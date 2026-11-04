# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'systemd::unit_file' do
  let(:unit_content) do
    <<~UNIT
      [Unit]
      Description=#{description}

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      ExecStart=/bin/true

      [Install]
      WantedBy=multi-user.target
    UNIT
  end

  let(:manifest) do
    <<~PUPPET
      systemd::unit_file { 'acceptance-oneshot.service':
        content => '#{unit_content}',
        enable  => true,
        active  => true,
      }
    PUPPET
  end

  context 'with an enabled and active service' do
    let(:description) { 'Acceptance oneshot' }

    it_behaves_like 'an idempotent resource'

    describe file('/etc/systemd/system/acceptance-oneshot.service') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 444 }
      it { is_expected.to be_owned_by 'root' }
      its(:content) { is_expected.to eq unit_content }
    end

    describe service('acceptance-oneshot.service') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  context 'when the content changes' do
    let(:description) { 'Acceptance oneshot changed' }

    it_behaves_like 'an idempotent resource'

    describe command('systemctl show --property=Description --value acceptance-oneshot.service') do
      its(:stdout) { is_expected.to eq "Acceptance oneshot changed\n" }
    end

    describe command('systemctl show --property=NeedDaemonReload --value acceptance-oneshot.service') do
      its(:stdout) { is_expected.to eq "no\n" }
    end
  end

  context 'with ensure absent' do
    let(:manifest) do
      <<~PUPPET
        systemd::unit_file { 'acceptance-oneshot.service':
          ensure => absent,
          enable => false,
          active => false,
        }
      PUPPET
    end

    it_behaves_like 'an idempotent resource'

    %w[
      /etc/systemd/system/acceptance-oneshot.service
      /etc/systemd/system/multi-user.target.wants/acceptance-oneshot.service
    ].each do |path|
      describe file(path) do
        it { is_expected.not_to exist }
      end
    end

    describe command('systemctl show --property=LoadState --value acceptance-oneshot.service') do
      its(:stdout) { is_expected.to eq "not-found\n" }
    end
  end

  # Without a Service to restart, only the module's daemon-reload makes systemd see the change
  context 'without a managed service' do
    let(:manifest) do
      <<~PUPPET
        systemd::unit_file { 'acceptance-unmanaged.service':
          content => "[Unit]\\nDescription=#{description}\\n\\n[Service]\\nType=oneshot\\nRemainAfterExit=yes\\nExecStart=/bin/true\\n",
        }
      PUPPET
    end

    context 'when started outside Puppet' do
      let(:description) { 'Unmanaged one' }

      it_behaves_like 'an idempotent resource'

      describe command('systemctl start acceptance-unmanaged.service') do
        its(:exit_status) { is_expected.to eq 0 }
      end
    end

    context 'when the content changes' do
      let(:description) { 'Unmanaged two' }

      it_behaves_like 'an idempotent resource'

      describe command('systemctl show --property=Description --value acceptance-unmanaged.service') do
        its(:stdout) { is_expected.to eq "Unmanaged two\n" }
      end

      describe command('systemctl show --property=NeedDaemonReload --value acceptance-unmanaged.service') do
        its(:stdout) { is_expected.to eq "no\n" }
      end
    end
  end
end
