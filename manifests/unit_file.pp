# Creates a systemd unit file
#
# @api public
#
# @see systemd.unit(5)
#
# @attr name [Pattern['^.+\.(service|socket|device|mount|automount|swap|target|path|timer|slice|scope)$']]
#   The target unit file to create
#
#   * Must not contain ``/``
#
# @attr path
#   The main systemd configuration path
#
# @attr content
#   The full content of the unit file
#
#   * Mutually exclusive with ``$source``
#
# @attr source
#   The ``File`` resource compatible ``source``
#
#   * Mutually exclusive with ``$content``
#
# @attr target
#   If set, will force the file to be a symlink to the given target
#
#   * Mutually exclusive with both ``$source`` and ``$content``
#
define systemd::unit_file(
  Enum['file', 'absent']         $ensure  = 'file',
  Stdlib::Absolutepath           $path    = '/etc/systemd/system',
  Optional[String]               $content = undef,
  Optional[String]               $source  = undef,
  Optional[Stdlib::Absolutepath] $target  = undef,
) {
  include ::systemd

  assert_type(Systemd::Unit, $title)

  if $target {
    $_ensure = 'link'
  } else {
    $_ensure = $ensure
  }

  file { "${path}/${title}":
    ensure  => $_ensure,
    content => $content,
    source  => $source,
    target  => $target,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Class['systemd::systemctl::daemon_reload'],
  }
}
