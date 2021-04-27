# Creates a drop-in file for a systemd unit
#
# @api public
#
# @see systemd.unit(5)
#
# @param name [Pattern['^[^/]+\.conf$']]
#   The target unit file to create
#
# @param path
#   The main systemd configuration path
#
# @param selinux_ignore_defaults
#   If Puppet should ignore the default SELinux labels.
#
# @param content
#   The full content of the unit file
#
#   * Mutually exclusive with ``$source``
#
# @param source
#   The ``File`` resource compatible ``source``
#
#   * Mutually exclusive with ``$content``
#
# @param target
#   If set, will force the file to be a symlink to the given target
#
#   * Mutually exclusive with both ``$source`` and ``$content``
#
# @param owner
#   The owner to set on the dropin file
#
# @param group
#   The group to set on the dropin file
#
# @param mode
#   The mode to set on the dropin file
#
# @param show_diff
#   Whether to show the diff when updating dropin file
#
# @param notify_service
#   Notify a service for the unit, if it exists
#
define systemd::dropin_file (
  Systemd::Unit                               $unit,
  Systemd::Dropin                             $filename                = $name,
  Enum['present', 'absent', 'file']           $ensure                  = 'present',
  Stdlib::Absolutepath                        $path                    = '/etc/systemd/system',
  Optional[Boolean]                           $selinux_ignore_defaults = false,
  Optional[Variant[String,Sensitive[String]]] $content                 = undef,
  Optional[String]                            $source                  = undef,
  Optional[Stdlib::Absolutepath]              $target                  = undef,
  String                                      $owner                   = 'root',
  String                                      $group                   = 'root',
  String                                      $mode                    = '0444',
  Boolean                                     $show_diff               = true,
  Boolean                                     $notify_service          = true,
) {
  include systemd

  if $target {
    $_ensure = 'link'
  } else {
    $_ensure = $ensure ? {
      'present' => 'file',
      default   => $ensure,
    }
  }

  $full_filename = "${path}/${unit}.d/${filename}"

  if $ensure != 'absent' {
    ensure_resource('file', dirname($full_filename), {
        ensure                  => directory,
        owner                   => 'root',
        group                   => 'root',
        recurse                 => $systemd::purge_dropin_dirs,
        purge                   => $systemd::purge_dropin_dirs,
        selinux_ignore_defaults => $selinux_ignore_defaults,
    })
  }

  file { $full_filename:
    ensure                  => $_ensure,
    content                 => $content,
    source                  => $source,
    target                  => $target,
    owner                   => $owner,
    group                   => $group,
    mode                    => $mode,
    selinux_ignore_defaults => $selinux_ignore_defaults,
    show_diff               => $show_diff,
  }

  if $notify_service {
    File[$full_filename] ~> Service <| title == $unit or name == $unit |>
    if $unit =~ /\.service$/ {
      $short_service_name = regsubst($unit, /\.service$/, '')
      File[$full_filename] ~> Service <| title == $short_service_name or name == $short_service_name |>
    }
  }
}
