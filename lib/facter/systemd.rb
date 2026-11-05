# frozen_string_literal: true

# Fact: systemd
#
# Purpose:
#   Determine whether systemd is the init system on the node
#
# Resolution:
#   Check if the service_provider fact is systemd
#
# Caveats:
#   If you override the service provider then it will return false, even if the
#   underlying system still is systemd.
#

# Fact: systemd_version
#
# Purpose:
#   Determine the version of systemd installed
#
# Resolution:
#   Check the output of systemctl --version
#
# Caveats:
#

# Fact: systemd_internal_services
#
# Purpose:
#   List all systemd internal real services + their state
#
# Resolution:
#   Check the output of systemctl --list-unit-files systemd-* and parse it into
#   a hash with the status
#
# Caveats:
#

# Fact: systemd_machine_info
#
# Purpose:
#   Provide structured machine information from systemd's machine-info
#
# Resolution:
#   Parse the JSON output from hostnamectl --json=short
#
# Caveats:
#   Requires hostnamectl to be available
#
Facter.add(:systemd) do
  confine kernel: :linux
  setcode do
    Facter.value(:service_provider) == 'systemd'
  end
end

Facter.add(:systemd_version) do
  confine systemd: true
  setcode do
    Facter::Core::Execution.execute("systemctl --version | awk '/systemd/{ print $2 }'")
  end
end

Facter.add(:systemd_internal_services) do
  confine systemd: true
  setcode do
    command_output = Facter::Core::Execution.execute(
      'systemctl list-unit-files --no-legend --no-pager "systemd-*" -t service --state=enabled,disabled,enabled-runtime,indirect,masked',
    )
    lines = command_output.lines.lazy.map { |line| line.split(%r{\s+}) }
    lines.each_with_object({}) do |(service, status, *), result|
      result[service] = status
    end
  end
end

Facter.add(:systemd_machine_info) do
  confine systemd: true
  setcode do
    command_output = Facter::Core::Execution.execute('hostnamectl --json=short 2>/dev/null')
    json_data = JSON.parse(command_output)

    # The /etc/machine-info settings (PRETTY_HOSTNAME, CHASSIS, DEPLOYMENT,
    # LOCATION, TAGS, etc.) are not top-level keys; they are nested as
    # "KEY=value" strings inside the MachineInformationData array.
    machine_info_data = json_data['MachineInformationData'] || []

    result = {}
    machine_info_data.each do |entry|
      key, value = entry.split('=', 2)
      result[key] = if key == 'TAGS'
                      # TAGS is a colon-separated string; split and sort
                      value.to_s.split(':').reject(&:empty?).sort
                    else
                      value
                    end
    end
    result
  rescue JSON::ParserError
    nil
  end
end
