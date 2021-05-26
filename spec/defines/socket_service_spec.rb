require 'spec_helper'

describe 'systemd::socket_service' do
  let(:title) { 'myservice' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'ensure => running' do
        let(:params) do
          {
            ensure: 'running',
            socket_content: "[Socket]\nListenStream=/run/myservice.socket\n",
            service_content: "[Service]\nType=notify\n",
          }
        end

        it { is_expected.to compile.with_all_deps }
        it 'sets up the socket unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.socket')
            .with_ensure('file')
            .with_content(%r{\[Socket\]})
            .that_comes_before(['Service[myservice.socket]', 'Service[myservice.service]'])
        end
        it 'sets up the socket service' do
          is_expected.to contain_service('myservice.socket')
            .with_ensure(true)
            .with_enable(true)
        end
        it 'sets up the service unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.service')
            .with_ensure('file')
            .with_content(%r{\[Service\]})
            .that_comes_before('Service[myservice.service]')
        end
        it 'sets up the service service' do
          is_expected.to contain_service('myservice.service')
            .with_ensure(true)
            .with_enable(true)
        end

        context 'enable => false' do
          let(:params) { super().merge(enable: false) }

          it { is_expected.to compile.with_all_deps }
          it 'sets up the socket service' do
            is_expected.to contain_service('myservice.socket')
              .with_ensure(true)
              .with_enable(false)
          end
          it 'sets up the service service' do
            is_expected.to contain_service('myservice.service')
              .with_ensure(true)
              .with_enable(false)
          end
        end
      end

      context 'ensure => stopped' do
        let(:params) do
          {
            ensure: 'stopped',
            socket_content: "[Socket]\nListenStream=/run/myservice.socket\n",
            service_content: "[Service]\nType=notify\n",
          }
        end

        it { is_expected.to compile.with_all_deps }
        it 'sets up the socket unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.socket')
            .with_ensure('file')
            .with_content(%r{\[Socket\]})
            .that_comes_before(['Service[myservice.socket]', 'Service[myservice.service]'])
        end
        it 'sets up the socket service' do
          is_expected.to contain_service('myservice.socket')
            .with_ensure(false)
            .with_enable(false)
        end
        it 'sets up the service unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.service')
            .with_ensure('file')
            .with_content(%r{\[Service\]})
            .that_comes_before('Service[myservice.service]')
        end
        it 'sets up the service service' do
          is_expected.to contain_service('myservice.service')
            .with_ensure(false)
            .with_enable(false)
        end

        context 'enable => true' do
          let(:params) { super().merge(enable: true) }

          it { is_expected.to compile.with_all_deps }
          it 'sets up the socket service' do
            is_expected.to contain_service('myservice.socket')
              .with_ensure(false)
              .with_enable(true)
          end
          it 'sets up the service service' do
            is_expected.to contain_service('myservice.service')
              .with_ensure(false)
              .with_enable(true)
          end
        end
      end

      context 'ensure => present' do
        let(:params) do
          {
            ensure: 'present',
            socket_content: "[Socket]\nListenStream=/run/myservice.socket\n",
            service_content: "[Service]\nType=notify\n",
          }
        end

        it { is_expected.to compile.with_all_deps }
        it 'sets up the socket unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.socket')
            .with_ensure('file')
            .with_content(%r{\[Socket\]})
        end
        it "doesn't set up the socket service" do
          is_expected.not_to contain_service('myservice.socket')
        end
        it 'sets up the service unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.service')
            .with_ensure('file')
            .with_content(%r{\[Service\]})
        end
        it "doesn't set up the service service" do
          is_expected.not_to contain_service('myservice.service')
        end

        context 'enable => true' do
          let(:params) { super().merge(enable: true) }

          it { is_expected.to compile.with_all_deps }
          it 'sets up the socket service' do
            is_expected.to contain_service('myservice.socket')
              .without_ensure
              .with_enable(true)
          end
          it 'sets up the service service' do
            is_expected.to contain_service('myservice.service')
              .without_ensure
              .with_enable(true)
          end
        end
      end

      context 'ensure => absent' do
        let(:params) do
          {
            ensure: 'absent',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it 'sets up the socket unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.socket')
            .with_ensure('absent')
            .without_content
            .that_requires('Service[myservice.socket]')
        end
        it 'sets up the socket service' do
          is_expected.to contain_service('myservice.socket')
            .with_ensure(false)
            .with_enable(false)
        end
        it 'sets up the service unit file' do
          is_expected.to contain_file('/etc/systemd/system/myservice.service')
            .with_ensure('absent')
            .without_content
            .that_requires('Service[myservice.service]')
        end
        it 'sets up the service service' do
          is_expected.to contain_service('myservice.service')
            .with_ensure(false)
            .with_enable(false)
        end
      end
    end
  end
end
