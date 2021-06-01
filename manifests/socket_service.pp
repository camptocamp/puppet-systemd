# @summary Create a systemd socket activated service
# @api public
#
# Systemd socket activated services have their own dependencies. This is a
# convenience wrapper around systemd::unit_file.
#
# @param name [Pattern['^[^/]+$']]
#   The target unit file to create
# @param socket_content
#   The content for the socket unit file. Required if ensure isn't absent.
# @param service_content
#   The content for the service unit file. Required if ensure isn't absent.
# @param enable
#   Whether to enable or disable the service. By default this is derived from
#   $ensure but can be overridden for advanced use cases where the service is
#   running during a migration but shouldn't be enabled on boot.
define systemd::socket_service (
  Enum['running', 'stopped', 'present', 'absent'] $ensure = 'running',
  Optional[String[1]] $socket_content = undef,
  Optional[String[1]] $service_content = undef,
  Optional[Boolean] $enable = undef,
) {
  assert_type(Pattern['^[^/]+$'], $name)

  if $ensure != 'absent' {
    assert_type(NotUndef, $socket_content)
    assert_type(NotUndef, $service_content)
  }

  $active = $ensure ? {
    'running' => true,
    'stopped' => false,
    'absent'  => false,
    default   => undef,
  }
  # https://tickets.puppetlabs.com/browse/MODULES-11018
  if $enable == undef and $active == undef {
    $real_enable = undef
  } else {
    $real_enable = pick($enable, $active)
  }

  $unit_file_ensure = bool2str($ensure == 'absent', 'absent', 'present')

  systemd::unit_file { "${name}.socket":
    ensure  => $unit_file_ensure,
    content => $socket_content,
    active  => $active,
    enable  => $real_enable,
  }

  systemd::unit_file { "${name}.service":
    ensure  => $unit_file_ensure,
    content => $service_content,
    active  => $active,
    enable  => $real_enable,
  }

  if $active != undef or $real_enable != undef {
    # Systemd needs both .socket and .service to be loaded when starting the
    # service. The unit_file takes care of matching, this ensures the
    # non-matching order.
    File["/etc/systemd/system/${name}.socket"] -> Service["${name}.service"]
    File["/etc/systemd/system/${name}.service"] -> Service["${name}.socket"]
  }
}
