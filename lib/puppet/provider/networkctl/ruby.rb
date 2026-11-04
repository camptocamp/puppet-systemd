# frozen_string_literal: true

require 'json'

# @summary custom provider to manage systemd user sessions/linger
# @see https://www.freedesktop.org/software/systemd/man/loginctl.html
# @see https://wiki.archlinux.org/title/Systemd/User
Puppet::Type.type(:networkctl).provide(:ruby) do
  desc 'custom provider to manage network interfaces'
  commands networkctl: 'networkctl'

  def self.instances
    interfaces = JSON.parse(networkctl('--full', '--json', 'pretty'))['Interfaces']
    interfaces.map do |interface|
      Puppet.debug("processing interface: #{interface}")
      mac = interface['HardwareAddress'] ? '%02x:%02x:%02x:%02x:%02x:%02x' % interface['HardwareAddress'] : nil
      data = {
        name: interface['Name'],
        type: interface['Type'],
        minimum_mtu: interface['MinimumMTU'],
        maximum_mtu: interface['MaximumMTU'],
        mtu: interface['MTU'],
        administrative_state: interface['AdministrativeState'],
        operational_state: interface['OperationalState'],
        carrier_state: interface['CarrierState'],
        address_state: interface['AddressState'],
        ipv4_address_state: interface['IPv4AddressState'],
        ipv6_address_state: interface['IPv6AddressState'],
        driver: interface['Driver'],
        link_file: interface['LinkFile'],
        path: interface['Path'],
        vendor: interface['Vendor'],
        model: interface['Model'],
        flags: interface['Flags'],
        flags_string: interface['FlagsString'],
        kernel_operational_state: interface['KernelOperationalState'],
        kernel_operational_state_string: interface['KernelOperationalStateString'],
        hardware_address: mac,
      }.compact
      new(data)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      resources[prov.name].provider = prov if resources[prov.name]
    end
  end

  mk_resource_methods
end
