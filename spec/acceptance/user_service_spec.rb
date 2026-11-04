# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'systemd::user_service' do
  context 'create and start a user unit' do
    let(:manifest) do
      <<~PUPPET

        # systemd-logind.service must be running.
        class{ 'systemd':
          manage_logind   => true,
          install_runuser => true,
        }

        user { 'higgs' :
          ensure     => present,
          managehome => true,
        }

        loginctl_user{'higgs':
          linger  => enabled,
        }

        # Assumes home directory was created as /home/higgs
        file{['/home/higgs/.config', '/home/higgs/.config/systemd','/home/higgs/.config/systemd/user']:
          ensure => directory,
          owner  => higgs,
        }

        systemd::manage_unit{ 'hour.service':
          ensure        => present,
          owner         => higgs,
          path          => '/home/higgs/.config/systemd/user',
          unit_entry    => {
            'Description' => 'hang around for an hour',
          },
          service_entry => {
            'ExecStart' => '/usr/bin/sleep 1h'
          },
          install_entry => {
            'WantedBy' => 'default.target'
          },
          notify => Systemd::Daemon_reload['hour reload'],
        }

        systemd::daemon_reload{'hour reload':
          user => 'higgs',
        }

        systemd::user_service { 'hour.service':
          ensure    => true,
          enable    => true,
          user      => 'higgs',
          subscribe =>  Systemd::Daemon_reload['hour reload'],
        }

      PUPPET
    end

    it 'works idempotently with no errors' do
      skip 'we know old OSes do not work' if
        ((fact('os.name') == 'Debian') && (fact('os.release.major') == '11')) ||
        ((fact('os.name') == 'Ubuntu') && (fact('os.release.major') == '22.04')) ||
        ((fact('os.family') == 'RedHat') && (fact('os.release.major') == '8'))
      apply_manifest(manifest, catch_failures: true)
      apply_manifest(manifest, catch_changes: true)
    end

    describe 'hour.service user unit' do
      it 'is running' do
        skip 'we know old OSes do not work' if
          ((fact('os.name') == 'Debian') && (fact('os.release.major') == '11')) ||
          ((fact('os.name') == 'Ubuntu') && (fact('os.release.major') == '22.04')) ||
          ((fact('os.family') == 'RedHat') && (fact('os.release.major') == '8'))

        result = command('systemctl --user --machine higgs@ is-active hour.service')
        expect(result.stdout.strip).to eq('active')
      end

      it 'is enabled' do
        skip 'we know old OSes do not work' if
          ((fact('os.name') == 'Debian') && (fact('os.release.major') == '11')) ||
          ((fact('os.name') == 'Ubuntu') && (fact('os.release.major') == '22.04')) ||
          ((fact('os.family') == 'RedHat') && (fact('os.release.major') == '8'))

        result = command('systemctl --user --machine higgs@ is-enabled hour.service')
        expect(result.stdout.strip).to eq('enabled')
      end
    end
  end
end
