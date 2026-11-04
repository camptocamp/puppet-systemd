# frozen_string_literal: true

require 'spec_helper'

describe 'systemd::manage_unit' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }

        let(:title) { 'foobar.service' }

        context 'with an arrayed description and simple parameters set' do
          let(:params) do
            {
              comments: [
                'some comment',
                '  some other comment',
              ],
              unit_entry: {
                Description: ['My great service', 'has two lines of description'],
                DefaultDependencies: true,
                ConditionPathExists: '%h/.config/myapp/config.json',
              },
              service_entry: {
                Type: 'oneshot',
                ExecStart: '/usr/bin/doit.sh',
                SyslogIdentifier: 'doit-backwards.sh',
                Environment: ['bla=foo', 'foo=bla'],
                EnvironmentFile: '%h/.config/myapp/env',
                IOReadIOPSMax: ['/dev/afs', '1K'],
              },
              install_entry: {
                WantedBy: 'multi-user.target',
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('foobar.service')
              .with_content(%r{^# some comment})
              .with_content(%r{^#   some other comment})
              .with_content(%r{^\[Unit\]$})
              .with_content(%r{^DefaultDependencies=true$})
              .with_content(%r{^ConditionPathExists=%h/\.config/myapp/config\.json$})
              .with_content(%r{^\[Service\]$})
              .with_content(%r{^EnvironmentFile=%h/\.config/myapp/env$})
              .with_content(%r{^SyslogIdentifier=doit-backwards\.sh$})
              .with_content(%r{^Environment=bla=foo$})
              .with_content(%r{^Environment=foo=bla$})
              .with_content(%r{^\[Install\]$})
              .with_content(%r{^Description=My great service$})
              .with_content(%r{^Description=has two lines of description$})
              .with_content(%r{^Type=oneshot$})
              .with_content(%r{^IOReadIOPSMax=/dev/afs 1K$})
              .without_content(%r{^\[Slice\]$})
          }

          context 'with no service_entry' do
            let(:params) do
              {
                ensure: 'present',
              }
            end

            it { is_expected.to compile.and_raise_error(%r{service_entry is required for service units}) }

            context 'with ensure absent' do
              let(:params) do
                super().merge(ensure: 'absent')
              end

              it { is_expected.to contain_systemd__unit_file('foobar.service').with_ensure('absent') }
            end
          end

          context 'with a timer entry' do
            let(:params) do
              super().merge(timer_entry: { 'OnCalendar' => 'something' })
            end

            it { is_expected.to compile.and_raise_error(%r{timer_entry is only valid for timer units}) }
          end

          context 'with a slice entry' do
            let(:params) do
              super().merge(slice_entry: { 'IOWeight' => 100 })
            end

            it { is_expected.to compile.and_raise_error(%r{slice_entry is only valid for slice units}) }
          end

          context 'with a path entry' do
            let(:params) do
              super().merge(path_entry: { 'PathExists' => '/etc/passwd' })
            end

            it { is_expected.to compile.and_raise_error(%r{path_entry is only valid for path units}) }
          end

          context 'with a socket entry' do
            let(:params) do
              super().merge(socket_entry: { 'ListenStream' => '1337' })
            end

            it { is_expected.to compile.and_raise_error(%r{socket_entry is only valid for socket units}) }
          end
        end

        context 'on an automount' do
          let(:title) { 'some-dir.automount' }

          let(:params) do
            {
              unit_entry: {
                Description: 'Automount /some/dir',
              },
              automount_entry: {
                'Where' => '/some/dir',
                'TimeoutIdleSec' => '5min 20s',
              },
              install_entry: {
                WantedBy: 'multi-user.target',
              },
            }
          end

          it do
            is_expected.to compile.with_all_deps

            is_expected.to contain_systemd__unit_file('some-dir.automount')
              .with_content(<<~CONTENT)
                # Deployed with puppet
                #

                [Unit]
                Description=Automount /some/dir

                [Automount]
                Where=/some/dir
                TimeoutIdleSec=5min 20s

                [Install]
                WantedBy=multi-user.target
              CONTENT
          end
        end

        context 'on a mount' do
          let(:title) { 'var-lib-sss-db.mount' }

          let(:params) do
            {
              unit_entry: {
                Description: 'Mount sssd dir',
              },
              mount_entry: {
                'What' => 'tmpfs',
                'Where' => '/var/lib/sss/db',
                'Type' => 'tmpfs',
                'Options' => 'size=300M',
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('var-lib-sss-db.mount')
              .with_content(%r{^\[Mount\]$})
              .with_content(%r{^What=tmpfs$})
              .with_content(%r{^Where=/var/lib/sss/db$})
              .with_content(%r{^Options=size=300M$})
          }
        end

        context 'when masking a unit' do
          let(:title) { 'tmpfs.mount' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/tmpfs.mount').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a service unit without service_entry' do
          let(:title) { 'masked.service' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.service').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a timer unit without timer_entry' do
          let(:title) { 'masked.timer' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.timer').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a socket unit without socket_entry' do
          let(:title) { 'masked.socket' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.socket').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a path unit without path_entry' do
          let(:title) { 'masked.path' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.path').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a slice unit without slice_entry' do
          let(:title) { 'masked.slice' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.slice').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking an automount unit without automount_entry' do
          let(:title) { 'masked.automount' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.automount').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'when masking a swap unit without swap_entry' do
          let(:title) { 'masked.swap' }

          let(:params) do
            {
              enable: 'mask',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/etc/systemd/system/masked.swap').with(
              ensure: 'link',
              target: '/dev/null',
            )
          }
        end

        context 'on a swap' do
          let(:title) { 'file.swap' }

          let(:params) do
            {
              unit_entry: {
                Description: 'Add swap from a file',
              },
              swap_entry: {
                'What' => '/file',
                'TimeoutSec' => 100,
                'Options' => 'trim',
                'Priority' => 10,
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('file.swap')
              .with_content(%r{^\[Swap\]$})
              .with_content(%r{^What=/file$})
              .with_content(%r{^TimeoutSec=100$})
              .with_content(%r{^Options=trim$})
              .with_content(%r{^Priority=10$})
          }
        end

        context 'on a timer' do
          let(:title) { 'winter.timer' }

          let(:params) do
            {
              unit_entry: {
                Description: 'Winter is coming',
              },
              timer_entry: {
                'OnActiveSec' => '5min',
                'OnBootSec' => ['', '1min 5s'],
                'OnStartUpSec' => 10,
                'OnUnitActiveSec' => '5s',
                'OnUnitInactiveSec' => ['', 10],
                'OnCalendar' => 'soon',
                'AccuracySec' => '24h',
                'RandomizedDelaySec' => '4min 20s',
                'FixedRandomDelay' => true,
                'OnClockChange' => false,
                'OnTimezoneChange' => true,
                'Unit' => 'summer.service',
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('winter.timer')
              .with_content(%r{^\[Timer\]$})
              .with_content(%r{^OnActiveSec=5min$})
              .with_content(%r{^OnBootSec=$})
              .with_content(%r{^OnBootSec=1min 5s$})
              .with_content(%r{^OnStartUpSec=10$})
              .with_content(%r{^OnUnitActiveSec=5s$})
              .with_content(%r{^OnUnitInactiveSec=$})
              .with_content(%r{^OnUnitInactiveSec=10$})
              .with_content(%r{^OnCalendar=soon$})
              .with_content(%r{^AccuracySec=24h$})
              .with_content(%r{^RandomizedDelaySec=4min 20s$})
              .with_content(%r{^FixedRandomDelay=true$})
              .with_content(%r{^OnClockChange=false$})
              .with_content(%r{^OnTimezoneChange=true$})
              .with_content(%r{^Unit=summer.service$})
          }
        end

        context 'on a socket unit' do
          let(:title) { 'arcd.socket' }
          let(:params) do
            {
              unit_entry: {
                Description: 'A crazy socket',
              },
              socket_entry: {
                'ListenStream' => 4241,
                'Accept'       => true,
                'BindIPv6Only' => 'both',
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('arcd.socket')
              .with_content(%r{^\[Socket\]$})
              .with_content(%r{^ListenStream=4241$})
              .with_content(%r{^Accept=true$})
              .with_content(%r{^BindIPv6Only=both$})
          }
        end

        context 'on a slice unit' do
          let(:title) { 'myslice.slice' }
          let(:params) do
            {
              unit_entry: {
                Description: 'A crazy slice',
              },
              slice_entry: {
                'MemoryMax' => '10G',
                'IOAccounting' => true,
                'IOWriteIOPSMax' => [
                  ['/dev/gluster', 20],
                  ['/dev/afs', '50K'],
                ],
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('myslice.slice')
              .with_content(%r{^\[Slice\]$})
              .with_content(%r{^MemoryMax=10G$})
              .with_content(%r{^IOAccounting=true$})
              .with_content(%r{^IOWriteIOPSMax=/dev/gluster 20$})
              .with_content(%r{^IOWriteIOPSMax=/dev/afs 50K$})
              .without_content(%r{^\[Service\]$})
          }
        end

        context 'on a path unit' do
          let(:title) { 'etc-passwd.path' }

          let(:params) do
            {
              unit_entry: {
                Description: 'Watch that passwd like a hawk',
              },
              path_entry: {
                'PathExists'              => '/etc/passwd',
                'PathExistsGlob'          => '/etc/krb5.conf.d/*.conf',
                'PathChanged'             => '',
                'PathModified'            => ['', '%h/.config/myapp/config.json', '/etc/httpd/conf.d/*.conf'],
                'DirectoryNotEmpty'       => '/tmp',
                'Unit'                    => 'my.service',
                'MakeDirectory'           => true,
                'DirectoryMode'           => '0777',
                'TriggerLimitIntervalSec' => '10s',
                'TriggerLimitBurst'       => 100,
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_systemd__unit_file('etc-passwd.path')
              .without_content(%r{^\[Service\]$})
              .with_content(%r{^\[Path\]$})
              .with_content(%r{^PathExists=/etc/passwd$})
              .with_content(%r{^PathExistsGlob=/etc/krb5.conf.d/\*.conf$})
              .with_content(%r{^PathChanged=$})
              .with_content(%r{^PathModified=$})
              .with_content(%r{^PathModified=%h/\.config/myapp/config\.json$})
              .with_content(%r{^PathModified=/etc/httpd/conf.d/\*.conf$})
              .with_content(%r{^DirectoryNotEmpty=/tmp$})
              .with_content(%r{^Unit=my.service$})
              .with_content(%r{^MakeDirectory=true$})
              .with_content(%r{^DirectoryMode=0777$})
              .with_content(%r{^TriggerLimitIntervalSec=10s$})
              .with_content(%r{^TriggerLimitBurst=100$})
          }
        end
      end
    end
  end
end
