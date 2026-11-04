# @summary An optional filesystem path value that may start with a systemd specifier (e.g. %h)
#
type Systemd::Unit::OptionalPathValue = Variant[
  Enum[''],
  Systemd::Unit::PathValue,
]
