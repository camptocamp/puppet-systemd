# frozen_string_literal: true

Puppet::Type.newtype(:networkctl) do
  newparam(:name, namevar: true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end
  newproperty(:type) do
    desc 'the Type'
    newvalues(%r{^\d+$})
  end
  newproperty(:minimum_mtu) do
    desc 'the minimum MTU'
    newvalues(%r{^\d+$})
  end
  newproperty(:maximum_mtu) do
    desc 'the maximum MTU'
    newvalues(%r{^\d+$})
  end
  newproperty(:mtu) do
    desc 'the actual MTU'
    newvalues(%r{^\d+$})
  end
  newproperty(:administrative_state) do
    desc 'the administrative state'
    newvalues(%r{.+})
  end
  newproperty(:operational_state) do
    desc 'a state'
    newvalues(%r{.+})
  end
  newproperty(:carrier_state) do
    desc 'another state'
    newvalues(%r{.+})
  end
  newproperty(:address_state) do
    desc 'address state'
    newvalues(%r{.+})
  end
  newproperty(:ipv4_address_state) do
    desc 'carrier'
    newvalues(%r{.+})
  end
  newproperty(:ipv6_address_state) do
    desc 'carrier'
    newvalues(%r{.+})
  end
  newproperty(:driver) do
    desc 'driver'
    # newvalues(%r{.+})
  end
  newproperty(:link_file) do
    desc 'link_file'
    # newvalues(%r{.+})
  end
  newproperty(:path) do
    desc 'path'
    # newvalues(%r{.+})
  end
  newproperty(:vendor) do
    desc 'Vendor'
    # newvalues(%r{.+})
  end
  newproperty(:model) do
    desc 'model'
    # newvalues(%r{.+})
  end
  newproperty(:flags) do
    desc 'Flags'
    # newvalues(%r{.+})
  end
  newproperty(:flags_string) do
    desc 'FlagsString'
    # newvalues(%r{.+})
  end
  newproperty(:kernel_operational_state) do
    desc 'KernelOperationalState'
    # newvalues(%r{.+})
  end
  newproperty(:kernel_operational_state_string) do
    desc 'KernelOperationalStateString'
    # newvalues(%r{.+})
  end
  newproperty(:hardware_address) do
    desc 'HardwareAddress'
    # newvalues(%r{.+})
  end
end
