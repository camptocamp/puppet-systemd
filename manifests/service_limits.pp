# Adds a set of custom limits to the service
#
# @api public
#
# @see systemd.exec(5)
#
# @param name [Pattern['^.+\.(service|socket|mount|swap)$']]
#   The name of the service that you will be modifying
#
# @param ensure
#   Whether to drop a file or remove it
#
# @param path
#   The path to the main systemd settings directory
#
# @param selinux_ignore_defaults
#   If Puppet should ignore the default SELinux labels.
#
# @param limits
#   A Hash of service limits matching the settings in ``systemd.exec(5)``
#
#   * Mutually exclusive with ``$source``
#
# @param source
#   A ``File`` resource compatible ``source``
#
#   * Mutually exclusive with ``$limits``
#
define systemd::service_limits (
  Enum['present', 'absent', 'file'] $ensure                  = 'present',
  Stdlib::Absolutepath              $path                    = '/etc/systemd/system',
  Optional[Boolean]                 $selinux_ignore_defaults = false,
  Optional[Systemd::ServiceLimits]  $limits                  = undef,
  Optional[String]                  $source                  = undef,
) {
  include systemd

  if $name !~ Pattern['^.+\.(service|socket|mount|swap)$'] {
    fail('$name must match Pattern["^.+\.(service|socket|mount|swap)$"]')
  }

  if $limits and !empty($limits) {
    $_content = template("${module_name}/limits.erb")
  }
  else {
    $_content = undef
  }

  if $ensure != 'absent' {
    if ($limits and !empty($limits)) and $source {
      fail('You may not supply both limits and source parameters to systemd::service_limits')
    }
    elsif ($limits == undef or empty($limits)) and ($source == undef) {
      fail('You must supply either the limits or source parameter to systemd::service_limits')
    }
  }

  systemd::dropin_file { "${name}-90-limits.conf":
    ensure                  => $ensure,
    unit                    => $name,
    filename                => '90-limits.conf',
    path                    => $path,
    selinux_ignore_defaults => $selinux_ignore_defaults,
    content                 => $_content,
    source                  => $source,
    notify_service          => true,
  }
}
