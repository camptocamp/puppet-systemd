# frozen_string_literal: true

# @summary custom provider to manage systemd user sessions/linger
# @see https://www.freedesktop.org/software/systemd/man/loginctl.html
# @see https://wiki.archlinux.org/title/Systemd/User
Puppet::Type.type(:loginctl_user).provide(:ruby) do
  desc 'custom provider to manage systemd user sessions/linger'

  commands loginctl: 'loginctl'

  def linger
    # loginctl is only successful if the user has an active session (so either logged in or lingering
    # so if loginctl fails, linger is definitly disabled, for users with an active session
    # (eg. logged in or running a timer or ...), the Linger property displays if lingering is activated.
    if loginctl('show-user', resource[:name], '--property=Linger', '--value').chomp == 'yes'
      :enabled
    else
      :disabled
    end
  rescue Puppet::ExecutionFailure
    :disabled
  end

  def linger=(value)
    case value
    when :enabled
      loginctl('enable-linger', resource[:name])
      # Wait for systemd --user instance to be ready after enabling linger
      wait_for_user_systemd_ready(resource[:name])
    when :disabled
      loginctl('disable-linger', resource[:name])
    end
  end

  def wait_for_user_systemd_ready(username, timeout = 10)
    # Try to connect to the user's systemd instance using loginctl show-user
    # which queries the user's systemd instance state
    start_time = Time.now
    loop do
      begin
        # Try to get user runtime directory which indicates systemd --user is running
        output = loginctl('show-user', username, '-p', 'RuntimePath')
        runtime_path = output.strip.split('=')[1]

        # Check if the systemd --user socket exists and is accessible
        if runtime_path && !runtime_path.empty?
          socket_path = "#{runtime_path}/systemd/private"
          if File.exist?(socket_path)
            # try to actually communicate with systemd --user
            # by checking if the user's systemd is in running state
            state_output = loginctl('show-user', username, '-p', 'State')
            state = state_output.strip.split('=')[1]
            if %w[active lingering].include?(state)
              Puppet.debug("systemd --user for #{username} is ready")
              break
            end
          end
        end
      rescue Puppet::ExecutionFailure => e
        # loginctl command failed, systemd --user might not be ready yet
        Puppet.debug("Waiting for systemd --user for #{username}: #{e.message}")
      end

      if Time.now - start_time > timeout
        Puppet.warning("Timeout waiting for systemd --user instance for user #{username} to become ready, continuing anyway")
        break
      end

      sleep 1
    end
  end
end
