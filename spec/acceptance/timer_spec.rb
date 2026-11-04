# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'systemd::timer' do
  let(:timer_content) do
    <<~UNIT
      [Unit]
      Description=Acceptance timer

      [Timer]
      OnCalendar=*-*-* 03:00:00

      [Install]
      WantedBy=timers.target
    UNIT
  end

  let(:service_content) do
    <<~UNIT
      [Unit]
      Description=Acceptance timer service

      [Service]
      Type=oneshot
      ExecStart=/bin/true
    UNIT
  end

  context 'with timer and service content, enabled and active' do
    let(:manifest) do
      <<~PUPPET
        systemd::timer { 'acceptance.timer':
          timer_content   => '#{timer_content}',
          service_content => '#{service_content}',
          active          => true,
          enable          => true,
        }
      PUPPET
    end

    it_behaves_like 'an idempotent resource'

    describe file('/etc/systemd/system/acceptance.timer') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 444 }
      its(:content) { is_expected.to eq timer_content }
    end

    describe file('/etc/systemd/system/acceptance.service') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode 444 }
      its(:content) { is_expected.to eq service_content }
    end

    describe service('acceptance.timer') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe command('systemctl show --property=TimersCalendar --value acceptance.timer') do
      its(:stdout) { is_expected.to match %r{OnCalendar=\*-\*-\* 03:00:00} }
    end

    describe command('systemctl show --property=LoadState --value acceptance.service') do
      its(:stdout) { is_expected.to eq "loaded\n" }
    end
  end

  context 'with ensure absent' do
    let(:manifest) do
      <<~PUPPET
        systemd::timer { 'acceptance.timer':
          ensure          => absent,
          timer_content   => '#{timer_content}',
          service_content => '#{service_content}',
          active          => false,
          enable          => false,
        }
      PUPPET
    end

    it_behaves_like 'an idempotent resource'

    %w[
      /etc/systemd/system/acceptance.timer
      /etc/systemd/system/acceptance.service
      /etc/systemd/system/timers.target.wants/acceptance.timer
    ].each do |path|
      describe file(path) do
        it { is_expected.not_to exist }
      end
    end

    %w[acceptance.timer acceptance.service].each do |unit|
      describe command("systemctl show --property=LoadState --value #{unit}") do
        its(:stdout) { is_expected.to eq "not-found\n" }
      end
    end
  end
end
