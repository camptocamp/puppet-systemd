# @summary A filesystem path value that may start with a systemd specifier (e.g. %h)
#
type Systemd::Unit::PathValue = Variant[
  Stdlib::Unixpath,
  Pattern[/\A%[A-Za-z][^\n\0]*\z/],
]
