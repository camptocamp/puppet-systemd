# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'systemd::dropin_file' do
  context 'on a timer' do
    let(:timer_content) do
      <<~UNIT
        [Timer]
        OnCalendar=*-*-* 03:00:00

        [Install]
        WantedBy=timers.target
      UNIT
    end

    # The empty OnCalendar= clears the timer's own schedule, otherwise both would apply.
    let(:dropin_content) { "[Timer]\nOnCalendar=\nOnCalendar=*-*-* #{hour}:00:00\n" }

    let(:dropin_ensure) { 'present' }

    let(:manifest) do
      <<~PUPPET
        systemd::timer { 'acceptance-dropin.timer':
          timer_content   => '#{timer_content}',
          service_content => "[Service]\\nType=oneshot\\nExecStart=/bin/true\\n",
          active          => true,
          enable          => true,
        }

        systemd::dropin_file { 'interval.conf':
          ensure  => #{dropin_ensure},
          unit    => 'acceptance-dropin.timer',
          content => '#{dropin_content}',
        }
      PUPPET
    end

    context 'with a drop-in overriding the schedule' do
      let(:hour) { '05' }

      it_behaves_like 'an idempotent resource'

      describe file('/etc/systemd/system/acceptance-dropin.timer.d') do
        it { is_expected.to be_directory }
        it { is_expected.to be_mode 755 }
      end

      describe file('/etc/systemd/system/acceptance-dropin.timer.d/interval.conf') do
        it { is_expected.to be_file }
        it { is_expected.to be_mode 444 }
        its(:content) { is_expected.to eq dropin_content }
      end

      describe command('systemctl show --property=DropInPaths --value acceptance-dropin.timer') do
        its(:stdout) { is_expected.to eq "/etc/systemd/system/acceptance-dropin.timer.d/interval.conf\n" }
      end

      describe command('systemctl show --property=TimersCalendar --value acceptance-dropin.timer') do
        its(:stdout) { is_expected.to match %r{OnCalendar=\*-\*-\* 05:00:00} }
        its(:stdout) { is_expected.not_to match %r{03:00:00} }
      end
    end

    context 'when the drop-in content changes' do
      let(:hour) { '06' }

      it_behaves_like 'an idempotent resource'

      describe command('systemctl show --property=TimersCalendar --value acceptance-dropin.timer') do
        its(:stdout) { is_expected.to match %r{OnCalendar=\*-\*-\* 06:00:00} }
        its(:stdout) { is_expected.not_to match %r{05:00:00} }
      end
    end

    context 'with ensure absent' do
      let(:hour) { '06' }
      let(:dropin_ensure) { 'absent' }

      it_behaves_like 'an idempotent resource'

      describe file('/etc/systemd/system/acceptance-dropin.timer.d/interval.conf') do
        it { is_expected.not_to exist }
      end

      describe command('systemctl show --property=DropInPaths --value acceptance-dropin.timer') do
        its(:stdout) { is_expected.to eq "\n" }
      end

      describe command('systemctl show --property=TimersCalendar --value acceptance-dropin.timer') do
        its(:stdout) { is_expected.to match %r{OnCalendar=\*-\*-\* 03:00:00} }
      end
    end
  end

  context 'from systemd::dropin_files on a service' do
    # The service only starts if the drop-in has cleared its failing condition.
    let(:manifest) do
      <<~PUPPET
        class { 'systemd':
          dropin_files => {
            'acceptance-condition' => {
              'unit'     => 'acceptance-condition.service',
              'filename' => 'no-condition.conf',
              'content'  => "[Unit]\\nConditionPathExists=\\n",
            },
          },
        }

        systemd::unit_file { 'acceptance-condition.service':
          content => "[Unit]\\nConditionPathExists=/nonexistent\\n\\n[Service]\\nType=oneshot\\nRemainAfterExit=yes\\nExecStart=/bin/true\\n",
          active  => true,
        }
      PUPPET
    end

    it_behaves_like 'an idempotent resource'

    describe file('/etc/systemd/system/acceptance-condition.service.d/no-condition.conf') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to eq "[Unit]\nConditionPathExists=\n" }
    end

    describe command('systemctl show --property=DropInPaths --value acceptance-condition.service') do
      its(:stdout) { is_expected.to eq "/etc/systemd/system/acceptance-condition.service.d/no-condition.conf\n" }
    end

    describe command('systemctl show --property=ConditionResult --value acceptance-condition.service') do
      its(:stdout) { is_expected.to eq "yes\n" }
    end

    describe service('acceptance-condition.service') do
      it { is_expected.to be_running }
    end
  end

  # Like a drop-in for a package's unit that Puppet doesn't manage as a service
  context 'on a running unit without a managed service' do
    let(:unit) do
      <<~PUPPET
        systemd::unit_file { 'acceptance-package.service':
          content => "[Service]\\nType=oneshot\\nRemainAfterExit=yes\\nExecStart=/bin/true\\n",
        }
      PUPPET
    end

    context 'when started outside Puppet' do
      let(:manifest) { unit }

      it_behaves_like 'an idempotent resource'

      describe command('systemctl start acceptance-package.service') do
        its(:exit_status) { is_expected.to eq 0 }
      end
    end

    context 'with a drop-in added' do
      let(:manifest) do
        <<~PUPPET
          #{unit}
          systemd::dropin_file { 'description.conf':
            unit    => 'acceptance-package.service',
            content => "[Unit]\\nDescription=Set by drop-in\\n",
          }
        PUPPET
      end

      it_behaves_like 'an idempotent resource'

      describe command('systemctl show --property=Description --value acceptance-package.service') do
        its(:stdout) { is_expected.to eq "Set by drop-in\n" }
      end

      describe command('systemctl show --property=NeedDaemonReload --value acceptance-package.service') do
        its(:stdout) { is_expected.to eq "no\n" }
      end
    end
  end
end
