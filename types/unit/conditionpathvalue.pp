# @summary A path value for Condition* settings.
#
# Supports:
# - absolute paths
# - systemd specifier-based paths (e.g. %h/...)
# - optional negation/trigger prefixes (!, | and |!)
#
# @api private
#
type Systemd::Unit::ConditionPathValue = Variant[
  Systemd::Unit::OptionalPathValue,
  Pattern[/\A(?:!|\||\|!)\/[^\n\0]*\z/],
  Pattern[/\A(?:!|\||\|!)%[A-Za-z][^\n\0]*\z/],
]
