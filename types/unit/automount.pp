# @summary Possible keys for the [Automount] section of a unit file
# @see https://www.freedesktop.org/software/systemd/man/latest/systemd.automount.html
type Systemd::Unit::Automount = Struct[
  {
    Optional['Where'] => Systemd::Unit::PathValue,
    Optional['ExtraOptions'] => String[1],
    Optional['DirectoryMode'] => Stdlib::Filemode,
    Optional['TimeoutIdleSec'] => Systemd::Timespan,
  }
]
