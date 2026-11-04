# frozen_string_literal: true

require 'spec_helper'

# =============================================================================
# Shared value fixtures
#
# Each constant covers one Puppet type shape.  Keeping them here makes it
# immediately obvious what the contract is for every group below and means a
# single edit propagates everywhere that shape is used.
# =============================================================================

# Variant[String, Array[String,1]]
# Any string (including empty) or a non-empty array of strings.
FREE_STRING_VALID   = ['value', '', ['value'], ['', 'value'], %w[alpha beta]].freeze
FREE_STRING_INVALID = [[], 42].freeze

# Variant[Enum[''], Systemd::Unit, Array[Variant[Enum[''], Systemd::Unit], 1]]
# Empty-string reset, a valid unit name (has extension, no leading slash),
# or a non-empty array of those.
UNIT_VALID = [
  'foobar.service',
  ['foobar.service'],
  %w[alpha.service beta.service],
  '',
  [''],
  ['', 'foobar.service'],
].freeze
UNIT_INVALID = [
  '/unitwith.service', # leading slash not permitted
  'noextension',       # must have a unit-type suffix
  ['noextension'],
].freeze

# Variant[Systemd::Unit::OptionalPathValue, Array[Systemd::Unit::OptionalPathValue, 1]]
# Empty-string reset, an absolute or specifier (%h/...) path, or a non-empty array of those.
# No negation prefix; no empty array.
ABSPATH_VALID = [
  '/an/absolute/path',
  '%h/.local/share',
  '',
  ['', '/an/absolute/path', '%h/.local/share'],
].freeze
ABSPATH_INVALID = [
  'not/absolute',
  '%/not/a/specifier',
  ['not/absolute'],
  [],
].freeze

# Variant[Systemd::Unit::AssertPathValue, Array[Systemd::Unit::AssertPathValue, 1]]
# Empty-string reset, absolute or specifier path, negated path (!...), or non-empty array of those.
# (Assert* keys use this pattern - only negation with !)
ASSERT_PATH_VALID = [
  '/my/path',
  '!/my/path',
  '%h/my/path',
  '!%h/my/path',
  '',
  ['', '/my/path', '!/my/other/path', '%h/my/path'],
].freeze
ASSERT_PATH_INVALID = [
  '|/my/path',
  '|!/my/path',
  '|%h/my/path',
  '!not/absolute',
  ['|/my/path'],
  ['|!/my/path'],
  'not/absolute',
  ['not/absolute'],
  [],
].freeze

# Variant[Systemd::Unit::ConditionPathValue, Array[Systemd::Unit::ConditionPathValue, 1]]
# Empty-string reset, absolute or specifier path, negated path (!...), triggering path (|...),
# or triggering negated path (|!...), or non-empty array of those.
# (Condition* keys use this pattern - supports both ! and |)
CONDITION_PATH_VALID = [
  '/my/path',
  '!/my/path',
  '|/my/path',
  '|!/my/path',
  '%h/my/path',
  '!%h/my/path',
  '|%h/my/path',
  '|!%h/my/path',
  '',
  ['', '/my/path', '!/my/other/path', '|/third/path', '|!/fourth/path', '%h/fifth/path'],
].freeze
CONDITION_PATH_INVALID = [
  'not/absolute',
  '!not/absolute',
  '|not/absolute',
  '!|/my/path',
  ['not/absolute'],
  [],
].freeze

# Boolean - native Ruby true/false only; systemd strings like 'yes' rejected.
BOOL_VALID   = [true, false].freeze
BOOL_INVALID = ['yes', '', 1].freeze

# Variant[Integer[0], String] - timeout values: non-negative integer or string
# (e.g. 'infinity', '5min').
TIMEOUT_VALID   = [0, 30, 'infinity', '5min', '30s'].freeze
TIMEOUT_INVALID = [-1, []].freeze

# =============================================================================
# Key groups - grouped first by value type, then alphabetically within Assert*
# and Condition* sections.  All constants live at file scope to satisfy
# Lint/ConstantDefinitionInBlock and RSpec/LeakyConstantDeclaration.
# =============================================================================

FREE_STRING_TOP_KEYS = %w[Description Documentation].freeze

UNIT_DEPENDENCY_KEYS = %w[
  Wants
  Requires
  Requisite
  BindsTo
  PartOf
  Upholds
  Conflicts
  Before
  After
  OnFailure
  OnSuccess
  PropagatesReloadTo
  ReloadPropagatedFrom
  PropagatesStopTo
  StopPropagatedFrom
  JoinsNamespaceOf
].freeze

JOB_MODE_KEYS  = %w[OnSuccessJobMode OnFailureJobMode].freeze
JOB_MODE_VALID = %w[
  fail
  replace
  replace-irreversibly
  isolate
  flush
  ignore-dependencies
  ignore-requirements
].freeze
JOB_MODE_INVALID = ['', 'unknown-mode'].freeze

UNIT_BOOL_KEYS = %w[
  IgnoreOnIsolate
  StopWhenUnneeded
  RefuseManualStart
  RefuseManualStop
  AllowIsolate
  DefaultDependencies
  SurviveFinalKillSignal
].freeze

COLLECT_MODE_VALID   = %w[inactive inactive-or-failed].freeze
COLLECT_MODE_INVALID = ['active', ''].freeze

ACTION_KEYS  = %w[FailureAction SuccessAction StartLimitAction JobTimeoutAction].freeze
ACTION_VALID = %w[
  none
  reboot reboot-force reboot-immediate
  poweroff poweroff-force poweroff-immediate
  exit exit-force
  soft-reboot soft-reboot-force
  kexec kexec-force
  halt halt-force halt-immediate
].freeze
ACTION_INVALID = ['', 'unknown-action'].freeze

EXIT_STATUS_KEYS    = %w[FailureActionExitStatus SuccessActionExitStatus].freeze
EXIT_STATUS_VALID   = ['', 0, 128, 255].freeze
EXIT_STATUS_INVALID = [-1, 256, '1'].freeze

TIMEOUT_KEYS = %w[JobTimeoutSec JobRunningTimeoutSec].freeze

PLAIN_STRING_KEYS = %w[RebootArgument JobTimeoutRebootArgument].freeze

# Assert* ------------------------------------------------------------------ #

ASSERT_FREE_STRING_KEYS = %w[
  AssertArchitecture
  AssertFirmware
  AssertVirtualization
  AssertHost
  AssertKernelCommandLine
  AssertKernelVersion
  AssertVersion
  AssertCredential
  AssertEnvironment
  AssertSecurity
  AssertCapability
  AssertNeedsUpdate
  AssertKernelModuleLoaded
  AssertUser
  AssertGroup
  AssertControlGroupController
  AssertMemory
  AssertCPUs
  AssertCPUFeature
  AssertOSRelease
  AssertMemoryPressure
  AssertCPUPressure
  AssertIOPressure
].freeze

ASSERT_BOOL_KEYS = %w[AssertACPower AssertFirstBoot].freeze

ASSERT_PATH_KEYS = %w[
  AssertPathExists
  AssertPathExistsGlob
  AssertPathIsDirectory
  AssertPathIsSymbolicLink
  AssertPathIsMountPoint
  AssertPathIsReadWrite
  AssertPathIsEncrypted
  AssertPathIsSocket
  AssertFileNotEmpty
  AssertDirectoryNotEmpty
  AssertFileIsExecutable
].freeze

# Condition* --------------------------------------------------------------- #

CONDITION_FREE_STRING_KEYS = %w[
  ConditionArchitecture
  ConditionFirmware
  ConditionVirtualization
  ConditionHost
  ConditionKernelCommandLine
  ConditionKernelVersion
  ConditionVersion
  ConditionCredential
  ConditionEnvironment
  ConditionSecurity
  ConditionCapability
  ConditionNeedsUpdate
  ConditionKernelModuleLoaded
  ConditionUser
  ConditionGroup
  ConditionControlGroupController
  ConditionMemory
  ConditionCPUs
  ConditionCPUFeature
  ConditionOSRelease
  ConditionMemoryPressure
  ConditionCPUPressure
  ConditionIOPressure
].freeze

CONDITION_BOOL_KEYS = %w[ConditionACPower ConditionFirstBoot].freeze

CONDITION_PATH_KEYS = %w[
  ConditionPathExists
  ConditionPathExistsGlob
  ConditionPathIsDirectory
  ConditionPathIsSymbolicLink
  ConditionPathIsMountPoint
  ConditionPathIsReadWrite
  ConditionPathIsEncrypted
  ConditionPathIsSocket
  ConditionDirectoryNotEmpty
  ConditionFileNotEmpty
  ConditionFileIsExecutable
].freeze

# =============================================================================
# Spec
# =============================================================================

describe 'Systemd::Unit::Unit' do
  # ---------------------------------------------------------------------------
  # Description / Documentation
  # Variant[String, Array[String,1]]
  # ---------------------------------------------------------------------------

  FREE_STRING_TOP_KEYS.each do |key|
    context key do
      FREE_STRING_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      FREE_STRING_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
      it { is_expected.not_to allow_value({ key => 10 }) }
    end
  end

  # ---------------------------------------------------------------------------
  # Unit dependencies
  # Variant[Enum[''], Systemd::Unit, Array[Variant[Enum[''], Systemd::Unit], 1]]
  # ---------------------------------------------------------------------------

  UNIT_DEPENDENCY_KEYS.each do |key|
    context key do
      UNIT_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      UNIT_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Mount path dependencies
  # Variant[Systemd::Unit::OptionalPathValue, Array[Systemd::Unit::OptionalPathValue, 1]]
  # Absolute or specifier paths - no negation prefix.
  # ---------------------------------------------------------------------------

  %w[RequiresMountsFor WantsMountsFor].each do |key|
    context key do
      ABSPATH_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      ABSPATH_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # JobMode
  # Enum[...] - no empty string, no unknown values
  # ---------------------------------------------------------------------------

  JOB_MODE_KEYS.each do |key|
    context key do
      JOB_MODE_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      JOB_MODE_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Boolean unit-behaviour flags
  # Boolean only - no 'yes'/'no' strings
  # ---------------------------------------------------------------------------

  UNIT_BOOL_KEYS.each do |key|
    context key do
      BOOL_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      BOOL_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # CollectMode
  # Enum['inactive', 'inactive-or-failed']
  # ---------------------------------------------------------------------------

  context 'CollectMode' do
    COLLECT_MODE_VALID.each   { |v| it { is_expected.to     allow_value({ 'CollectMode' => v }) } }
    COLLECT_MODE_INVALID.each { |v| it { is_expected.not_to allow_value({ 'CollectMode' => v }) } }
  end

  # ---------------------------------------------------------------------------
  # Action enums
  # FailureAction, SuccessAction, StartLimitAction, JobTimeoutAction
  # Enum[...] - no empty string, no unknown values
  # ---------------------------------------------------------------------------

  ACTION_KEYS.each do |key|
    context key do
      ACTION_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      ACTION_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # ExitStatus
  # Variant[Enum[''], Integer[0, 255]]
  # ---------------------------------------------------------------------------

  EXIT_STATUS_KEYS.each do |key|
    context key do
      EXIT_STATUS_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      EXIT_STATUS_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # StartLimit scalars
  # ---------------------------------------------------------------------------

  context 'StartLimitIntervalSec' do
    # Systemd::Timespan - non-negative integer or time string (e.g. 'infinity', '5min')
    it { is_expected.to     allow_value({ 'StartLimitIntervalSec' => '12 hours' }) }
    it { is_expected.to     allow_value({ 'StartLimitIntervalSec' => 'infinity' }) }
  end

  context 'StartLimitBurst' do
    # Integer[1] - positive integers only
    it { is_expected.to     allow_value({ 'StartLimitBurst' => 1 }) }
    it { is_expected.to     allow_value({ 'StartLimitBurst' => 5 }) }
    it { is_expected.not_to allow_value({ 'StartLimitBurst' => 0 }) }
    it { is_expected.not_to allow_value({ 'StartLimitBurst' => '5' }) }
  end

  # ---------------------------------------------------------------------------
  # Job / timeout scalars
  # Variant[Integer[0], String]
  # ---------------------------------------------------------------------------

  TIMEOUT_KEYS.each do |key|
    context key do
      TIMEOUT_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      TIMEOUT_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Plain string scalars (reboot argument strings)
  # String - any string including empty
  # ---------------------------------------------------------------------------

  PLAIN_STRING_KEYS.each do |key|
    context key do
      it { is_expected.to     allow_value({ key => 'my-reboot-arg' }) }
      it { is_expected.to     allow_value({ key => '' }) }
      it { is_expected.not_to allow_value({ key => 42 }) }
      it { is_expected.not_to allow_value({ key => [] }) }
    end
  end

  # ---------------------------------------------------------------------------
  # SourcePath
  # Systemd::Unit::PathValue - absolute or specifier path, no empty string
  # ---------------------------------------------------------------------------

  context 'SourcePath' do
    it { is_expected.to     allow_value({ 'SourcePath' => '/etc/myapp/myapp.conf' }) }
    it { is_expected.to     allow_value({ 'SourcePath' => '/run/generated.conf' }) }
    it { is_expected.to     allow_value({ 'SourcePath' => '%E/myapp/myapp.conf' }) }
    it { is_expected.not_to allow_value({ 'SourcePath' => 'relative/path' }) }
    it { is_expected.not_to allow_value({ 'SourcePath' => '' }) }
  end

  # ===========================================================================
  # Assert* keys
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Assert: free-string checks
  # Variant[String, Array[String,1]]
  # systemd accepts an optional leading '!' at runtime; we accept any string.
  # ---------------------------------------------------------------------------

  ASSERT_FREE_STRING_KEYS.each do |key|
    context key do
      FREE_STRING_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      FREE_STRING_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Assert: boolean checks
  # Boolean only
  # ---------------------------------------------------------------------------

  ASSERT_BOOL_KEYS.each do |key|
    context key do
      BOOL_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      BOOL_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Assert: path checks :
  #     absolute path
  #     negated (!...)
  #     empty-string reset allowed
  # Variant[Enum[''], Stdlib::Unixpath, Pattern[/^!.*$/], Array[...same..., 1]]
  # ---------------------------------------------------------------------------

  ASSERT_PATH_KEYS.each do |key|
    context key do
      ASSERT_PATH_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      ASSERT_PATH_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ===========================================================================
  # Condition* keys
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Condition: free-string checks
  # Variant[String, Array[String,1]]
  # ---------------------------------------------------------------------------

  CONDITION_FREE_STRING_KEYS.each do |key|
    context key do
      FREE_STRING_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      FREE_STRING_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Condition: boolean checks
  # Boolean only
  # ---------------------------------------------------------------------------

  CONDITION_BOOL_KEYS.each do |key|
    context key do
      BOOL_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      BOOL_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end

  # ---------------------------------------------------------------------------
  # Condition: path checks
  #     absolute path
  #     negated (!...)
  #     triggering (|.../|!...)
  #     empty-string reset allowed
  # Variant[Enum[''], Stdlib::Unixpath, Pattern[/^\|!?.*/], Array[...same..., 1]]
  # ---------------------------------------------------------------------------

  CONDITION_PATH_KEYS.each do |key|
    context key do
      CONDITION_PATH_VALID.each   { |v| it { is_expected.to     allow_value({ key => v }) } }
      CONDITION_PATH_INVALID.each { |v| it { is_expected.not_to allow_value({ key => v }) } }
    end
  end
end
