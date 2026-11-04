# @summary A path value for Assert* settings.
#
# Supports:
# - absolute paths
# - systemd specifier-based paths (e.g. %h/...)
# - optional negation prefix (!)
#
# @api private
#
type Systemd::Unit::AssertPathValue = Variant[
  Systemd::Unit::OptionalPathValue,
  Pattern[/\A!\/[^\n\0]*\z/],
  Pattern[/\A!%[A-Za-z][^\n\0]*\z/],
]
