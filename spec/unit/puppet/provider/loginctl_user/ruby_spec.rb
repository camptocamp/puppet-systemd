# frozen_string_literal: true

require 'spec_helper'
require 'puppet'

provider_class = Puppet::Type.type(:loginctl_user).provider(:ruby)
describe provider_class do
  let(:common_params) do
    {
      title: 'foo',
      linger: 'enabled',
      provider: 'ruby',
    }
  end

  context 'when enabling linger' do
    let(:resource) { Puppet::Type.type(:loginctl_user).new(common_params) }
    let(:provider) { resource.provider }

    it 'enables linger and waits for systemd --user to be ready' do
      expect(provider).to receive(:loginctl).with('enable-linger', 'foo')
      runtime_path_called = false
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'RuntimePath') do
        runtime_path_called = true
        "RuntimePath=/run/user/1000\n"
      end

      systemd_private_exists_called = false
      allow(File).to receive(:exist?).with('/run/user/1000/systemd/private') do
        systemd_private_exists_called = true
        true
      end

      state_called = false
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'State') do
        state_called = true
        "State=active\n"
      end
      expect(Puppet).to receive(:debug).with('systemd --user for foo is ready')

      provider.linger = :enabled

      expect(runtime_path_called).to be(true)
      expect(systemd_private_exists_called).to be(true)
      expect(state_called).to be(true)
    end

    it 'waits and retries if systemd --user is not immediately ready' do
      expect(provider).to receive(:loginctl).with('enable-linger', 'foo')

      runtime_path_calls = 0
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'RuntimePath') do
        runtime_path_calls += 1
        case runtime_path_calls
        when 1
          "RuntimePath=\n"
        else
          "RuntimePath=/run/user/1000\n"
        end
      end

      systemd_private_exists_calls = 0
      allow(File).to receive(:exist?).with('/run/user/1000/systemd/private') do
        systemd_private_exists_calls += 1
        case systemd_private_exists_calls
        when 1
          false
        else
          true
        end
      end

      state_calls = 0
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'State') do
        state_calls += 1
        case state_calls
        when 1
          "State=opening\n"
        else
          "State=lingering\n"
        end
      end

      expect(Puppet).to receive(:debug).with('systemd --user for foo is ready')

      allow(provider).to receive(:sleep)

      provider.linger = :enabled

      expect(runtime_path_calls).to eq(4)
      expect(systemd_private_exists_calls).to eq(3)
      expect(state_calls).to eq(2)
    end

    it 'handles loginctl failures gracefully while waiting' do
      expect(provider).to receive(:loginctl).with('enable-linger', 'foo')

      runtime_path_calls = 0
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'RuntimePath') do
        runtime_path_calls += 1
        raise(Puppet::ExecutionFailure, 'Failed to get user properties') if runtime_path_calls == 1

        "RuntimePath=/run/user/1000\n"
      end

      allow(File).to receive(:exist?).with('/run/user/1000/systemd/private').and_return(true)
      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'State').and_return("State=active\n")

      expect(Puppet).to receive(:debug).with(%r{Waiting for systemd --user for foo})
      expect(Puppet).to receive(:debug).with('systemd --user for foo is ready')

      allow(provider).to receive(:sleep)

      provider.linger = :enabled

      expect(runtime_path_calls).to eq(2)
    end

    it 'logs a warning and continues if timeout is exceeded' do
      expect(provider).to receive(:loginctl).with('enable-linger', 'foo')

      # Mock Time to simulate timeout
      start_time = Time.now
      allow(Time).to receive(:now).and_return(start_time, start_time + 11)

      allow(provider).to receive(:loginctl).with('show-user', 'foo', '-p', 'RuntimePath')
                                           .and_return("RuntimePath=\n")

      expect(Puppet).to receive(:warning).with(%r{Timeout waiting for systemd --user instance for user foo to become ready, continuing anyway})

      provider.linger = :enabled
    end
  end

  it 'disables linger without waiting' do
    resource = Puppet::Type.type(:loginctl_user).new(common_params)
    expect(provider_class).to receive(:loginctl).with('disable-linger', 'foo')
    resource.provider.linger = :disabled
  end
end
