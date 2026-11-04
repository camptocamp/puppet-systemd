# @summary Possible keys for the [Path] section of a unit file
# @see https://www.freedesktop.org/software/systemd/man/systemd.path.html
#
type Systemd::Unit::Path = Struct[
  {
    Optional['PathExists']              => Variant[Systemd::Unit::OptionalPathValue,Array[Systemd::Unit::OptionalPathValue,1]],
    Optional['PathExistsGlob']          => Variant[Systemd::Unit::OptionalPathValue,Array[Systemd::Unit::OptionalPathValue,1]],
    Optional['PathChanged']             => Variant[Systemd::Unit::OptionalPathValue,Array[Systemd::Unit::OptionalPathValue,1]],
    Optional['PathModified']            => Variant[Systemd::Unit::OptionalPathValue,Array[Systemd::Unit::OptionalPathValue,1]],
    Optional['DirectoryNotEmpty']       => Variant[Systemd::Unit::OptionalPathValue,Array[Systemd::Unit::OptionalPathValue,1]],
    Optional['Unit']                    => Systemd::Unit,
    Optional['MakeDirectory']           => Boolean,
    Optional['DirectoryMode']           => Pattern[/\A[0-7]{1,4}\z/],
    Optional['TriggerLimitIntervalSec'] => Systemd::Timespan,
    Optional['TriggerLimitBurst']       => Integer[0],
  }
]
