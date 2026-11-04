# frozen_string_literal: true

require 'spec_helper'
require 'type_aliases/shared_systemd_resource_control'

describe 'Systemd::Unit::Service' do
  # === Exec commands ===
  # ExecStart, ExecStartPre, ExecStartPost, ExecCondition,
  # ExecReload, ExecReloadPost, ExecStop, ExecStopPost
  %w[ExecStart ExecStartPre ExecStartPost ExecCondition ExecReload ExecReloadPost ExecStop ExecStopPost].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '/usr/bin/doit.sh' }) }
      it { is_expected.to allow_value({ key => ['/usr/bin/doit.sh'] }) }
      it { is_expected.to allow_value({ key => ['-/usr/bin/doit.sh', ':/doit.sh', '+/doit.sh', '!/doit.sh', '!!/doit.sh'] }) }
      it { is_expected.to allow_value({ key => '' }) }
      it { is_expected.to allow_value({ key => [''] }) }
      it { is_expected.to allow_value({ key => ['', '/doit.sh'] }) }
      it { is_expected.not_to allow_value({ key => '*/wrongprefix.sh' }) }
    end
  end

  # === Type= ===
  context 'Type=' do
    %w[simple exec forking oneshot dbus notify notify-reload idle].each do |val|
      it { is_expected.to allow_value({ 'Type' => val }) }
    end
    it { is_expected.not_to allow_value({ 'Type' => 'invalid' }) }
    it { is_expected.not_to allow_value({ 'Type' => 'Notify' }) }
  end

  # === ExitType= ===
  context 'ExitType=' do
    it { is_expected.to allow_value({ 'ExitType' => 'main' }) }
    it { is_expected.to allow_value({ 'ExitType' => 'cgroup' }) }
    it { is_expected.not_to allow_value({ 'ExitType' => 'other' }) }
  end

  # === RemainAfterExit=, GuessMainPID= ===
  %w[RemainAfterExit GuessMainPID].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => true }) }
      it { is_expected.to allow_value({ key => false }) }
      it { is_expected.not_to allow_value({ key => 'yes' }) }
    end
  end

  # === PIDFile= ===
  context 'PIDFile=' do
    it { is_expected.to allow_value({ 'PIDFile' => '/run/service.pid' }) }
    it { is_expected.to allow_value({ 'PIDFile' => '%t/service.pid' }) }
    it { is_expected.not_to allow_value({ 'PIDFile' => 'relative.pid' }) }
  end

  # === BusName= ===
  context 'BusName=' do
    it { is_expected.to allow_value({ 'BusName' => 'org.freedesktop.NetworkManager' }) }
    it { is_expected.not_to allow_value({ 'BusName' => '' }) }
  end

  # === KillSignal=, ReloadSignal= ===
  context 'KillSignal=' do
    it { is_expected.to allow_value({ 'KillSignal' => 'SIGTERM' }) }
    it { is_expected.to allow_value({ 'KillSignal' => 'SIGKILL' }) }
    it { is_expected.not_to allow_value({ 'KillSignal' => 'SIGterm' }) }
    it { is_expected.not_to allow_value({ 'KillSignal' => 9 }) }
  end

  context 'ReloadSignal=' do
    it { is_expected.to allow_value({ 'ReloadSignal' => 'SIGHUP' }) }
    it { is_expected.to allow_value({ 'ReloadSignal' => 'SIGUSR1' }) }
    it { is_expected.to allow_value({ 'ReloadSignal' => 'SIGUSR2' }) }
    it { is_expected.not_to allow_value({ 'ReloadSignal' => 'sighup' }) }
    it { is_expected.not_to allow_value({ 'ReloadSignal' => 'HUP' }) }
  end

  # === KillMode= ===
  context 'KillMode=' do
    %w[control-group mixed process none].each do |val|
      it { is_expected.to allow_value({ 'KillMode' => val }) }
    end
    it { is_expected.not_to allow_value({ 'KillMode' => 'wrong' }) }
  end

  # === Restart= ===
  context 'Restart=' do
    %w[no on-success on-failure on-abnormal on-watchdog on-abort always].each do |val|
      it { is_expected.to allow_value({ 'Restart' => val }) }
    end
    it { is_expected.not_to allow_value({ 'Restart' => 'sometimes' }) }
  end

  # === RestartMode= ===
  context 'RestartMode=' do
    %w[normal direct debug].each do |val|
      it { is_expected.to allow_value({ 'RestartMode' => val }) }
    end
    it { is_expected.not_to allow_value({ 'RestartMode' => 'invalid' }) }
  end

  # === RestartSec=, RestartMaxDelaySec= - time spans ===
  %w[RestartSec RestartMaxDelaySec].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => 0 }) }
      it { is_expected.to allow_value({ key => 5 }) }
      it { is_expected.to allow_value({ key => '100ms' }) }
      it { is_expected.to allow_value({ key => 'infinity' }) }
    end
  end

  # === RestartSteps= ===
  context 'RestartSteps=' do
    it { is_expected.to allow_value({ 'RestartSteps' => 0 }) }
    it { is_expected.to allow_value({ 'RestartSteps' => 4 }) }
    it { is_expected.not_to allow_value({ 'RestartSteps' => -1 }) }
    it { is_expected.not_to allow_value({ 'RestartSteps' => '4' }) }
  end

  # === SuccessExitStatus=, RestartPreventExitStatus=, RestartForceExitStatus= ===
  %w[SuccessExitStatus RestartPreventExitStatus RestartForceExitStatus].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '0' }) }
      it { is_expected.to allow_value({ key => '0 1 SIGTERM' }) }
    end
  end

  # === Timeout* ===
  %w[TimeoutStartSec TimeoutStopSec TimeoutAbortSec TimeoutSec RuntimeMaxSec RuntimeRandomizedExtraSec WatchdogSec].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => 0 }) }
      it { is_expected.to allow_value({ key => 30 }) }
      it { is_expected.to allow_value({ key => 'infinity' }) }
      it { is_expected.to allow_value({ key => '5min' }) }
    end
  end

  # === TimeoutStartFailureMode=, TimeoutStopFailureMode= ===
  %w[TimeoutStartFailureMode TimeoutStopFailureMode].each do |key|
    context "#{key}=" do
      %w[terminate abort kill].each do |val|
        it { is_expected.to allow_value({ key => val }) }
      end
      it { is_expected.not_to allow_value({ key => 'ignore' }) }
    end
  end

  # === NotifyAccess= ===
  context 'NotifyAccess=' do
    %w[none default main exec all].each do |val|
      it { is_expected.to allow_value({ 'NotifyAccess' => val }) }
    end
    it { is_expected.not_to allow_value({ 'NotifyAccess' => 'invalid' }) }
  end

  # === OOMPolicy= ===
  context 'OOMPolicy=' do
    %w[continue stop kill].each do |val|
      it { is_expected.to allow_value({ 'OOMPolicy' => val }) }
    end
    it { is_expected.not_to allow_value({ 'OOMPolicy' => 'ignore' }) }
  end

  # === RootDirectoryStartOnly=, NonBlocking= ===
  %w[RootDirectoryStartOnly NonBlocking].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => true }) }
      it { is_expected.to allow_value({ key => false }) }
      it { is_expected.not_to allow_value({ key => 'true' }) }
    end
  end

  # === Sockets= ===
  context 'Sockets=' do
    it { is_expected.to allow_value({ 'Sockets' => 'foo.socket' }) }
    it { is_expected.to allow_value({ 'Sockets' => ['foo.socket', 'bar.socket'] }) }
    it { is_expected.not_to allow_value({ 'Sockets' => '' }) }
    it { is_expected.not_to allow_value({ 'Sockets' => [] }) }
  end

  # === FileDescriptorStoreMax= ===
  context 'FileDescriptorStoreMax=' do
    it { is_expected.to allow_value({ 'FileDescriptorStoreMax' => 0 }) }
    it { is_expected.to allow_value({ 'FileDescriptorStoreMax' => 16 }) }
    it { is_expected.not_to allow_value({ 'FileDescriptorStoreMax' => -1 }) }
    it { is_expected.not_to allow_value({ 'FileDescriptorStoreMax' => '16' }) }
  end

  # === FileDescriptorStorePreserve= ===
  context 'FileDescriptorStorePreserve=' do
    %w[no yes restart].each do |val|
      it { is_expected.to allow_value({ 'FileDescriptorStorePreserve' => val }) }
    end
    it { is_expected.not_to allow_value({ 'FileDescriptorStorePreserve' => 'always' }) }
  end

  # === OpenFile= ===
  context 'OpenFile=' do
    it { is_expected.to allow_value({ 'OpenFile' => '/tmp/file' }) }
    it { is_expected.to allow_value({ 'OpenFile' => '/tmp/file:myfd' }) }
    it { is_expected.to allow_value({ 'OpenFile' => '/tmp/file:myfd:read-only' }) }
    it { is_expected.to allow_value({ 'OpenFile' => ['/tmp/file1', '/tmp/file2:other:append'] }) }
    it { is_expected.not_to allow_value({ 'OpenFile' => '' }) }
    it { is_expected.not_to allow_value({ 'OpenFile' => [] }) }
  end

  # === RefreshOnReload= ===
  context 'RefreshOnReload=' do
    it { is_expected.to allow_value({ 'RefreshOnReload' => true }) }
    it { is_expected.to allow_value({ 'RefreshOnReload' => false }) }
    it { is_expected.to allow_value({ 'RefreshOnReload' => ['extensions'] }) }
    it { is_expected.to allow_value({ 'RefreshOnReload' => ['credentials'] }) }
    it { is_expected.to allow_value({ 'RefreshOnReload' => %w[extensions credentials] }) }
    it { is_expected.not_to allow_value({ 'RefreshOnReload' => 'extensions' }) }
    it { is_expected.not_to allow_value({ 'RefreshOnReload' => ['invalid'] }) }
  end

  # === USBFunctionDescriptors=, USBFunctionStrings= ===
  %w[USBFunctionDescriptors USBFunctionStrings].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '/etc/usb/descriptors' }) }
      it { is_expected.to allow_value({ key => '%E/usb/descriptors' }) }
      it { is_expected.not_to allow_value({ key => 'relative/path' }) }
    end
  end

  # === CPU resource accounting and limits ===
  context 'CPUAccounting=' do
    it { is_expected.to allow_value({ 'CPUAccounting' => true }) }
    it { is_expected.to allow_value({ 'CPUAccounting' => false }) }
    it { is_expected.not_to allow_value({ 'CPUAccounting' => 'yes' }) }
  end

  context 'CPUShares=' do
    it { is_expected.to allow_value({ 'CPUShares' => 1024 }) }
    it { is_expected.to allow_value({ 'CPUShares' => 2 }) }
    it { is_expected.to allow_value({ 'CPUShares' => 262_144 }) }
    it { is_expected.not_to allow_value({ 'CPUShares' => 1 }) }
    it { is_expected.not_to allow_value({ 'CPUShares' => 262_145 }) }
  end

  context 'StartupCPUShares=' do
    it { is_expected.to allow_value({ 'StartupCPUShares' => 512 }) }
    it { is_expected.not_to allow_value({ 'StartupCPUShares' => 1 }) }
  end

  context 'CPUSchedulingPolicy=' do
    it { is_expected.to allow_value({ 'CPUSchedulingPolicy' => 'idle' }) }
    it { is_expected.to allow_value({ 'CPUSchedulingPolicy' => 'fifo' }) }
    it { is_expected.to allow_value({ 'CPUSchedulingPolicy' => '' }) }
    it { is_expected.not_to allow_value({ 'CPUSchedulingPolicy' => 'best-effort' }) }
  end

  # === Resource limits (ulimit) ===
  context 'LimitCPU=' do
    it { is_expected.to allow_value({ 'LimitCPU' => '60s' }) }
    it { is_expected.to allow_value({ 'LimitCPU' => '1h:2h' }) }
    it { is_expected.not_to allow_value({ 'LimitCPU' => 'random string' }) }
  end

  context 'LimitCORE=' do
    it { is_expected.to allow_value({ 'LimitCORE' => 'infinity' }) }
    it { is_expected.to allow_value({ 'LimitCORE' => '100M' }) }
    it { is_expected.to allow_value({ 'LimitCORE' => '100M:1G' }) }
    it { is_expected.not_to allow_value({ 'LimitCORE' => 'random string' }) }
  end

  %w[LimitFSIZE LimitDATA LimitSTACK LimitRSS LimitAS LimitMEMLOCK LimitMSGQUEUE].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => 'infinity' }) }
      it { is_expected.to allow_value({ key => '512M' }) }
      it { is_expected.to allow_value({ key => '1G:2G' }) }
      it { is_expected.not_to allow_value({ key => 'bad' }) }
    end
  end

  context 'LimitMEMLOCK= with soft:hard' do
    it { is_expected.to allow_value({ 'LimitMEMLOCK' => '100:100K' }) }
  end

  context 'LimitNOFILE= and LimitNPROC=' do
    it { is_expected.to allow_value({ 'LimitNOFILE' => 'infinity' }) }
    it { is_expected.to allow_value({ 'LimitNOFILE' => '65536' }) }
    it { is_expected.to allow_value({ 'LimitNOFILE' => '1024:65536' }) }
    it { is_expected.to allow_value({ 'LimitNOFILE' => -1 }) }
    it { is_expected.to allow_value({ 'LimitNPROC' => 'infinity' }) }
    it { is_expected.to allow_value({ 'LimitNPROC' => -1 }) }
  end

  context 'LimitLOCKS=' do
    it { is_expected.to allow_value({ 'LimitLOCKS' => 1 }) }
    it { is_expected.not_to allow_value({ 'LimitLOCKS' => 0 }) }
  end

  context 'LimitSIGPENDING=' do
    it { is_expected.to allow_value({ 'LimitSIGPENDING' => 100 }) }
    it { is_expected.not_to allow_value({ 'LimitSIGPENDING' => 0 }) }
  end

  context 'LimitNICE=' do
    it { is_expected.to allow_value({ 'LimitNICE' => 0 }) }
    it { is_expected.to allow_value({ 'LimitNICE' => 40 }) }
  end

  context 'LimitRTPRIO=' do
    it { is_expected.to allow_value({ 'LimitRTPRIO' => 0 }) }
    it { is_expected.to allow_value({ 'LimitRTPRIO' => 99 }) }
    it { is_expected.not_to allow_value({ 'LimitRTPRIO' => -1 }) }
  end

  context 'LimitRTTIME=' do
    it { is_expected.to allow_value({ 'LimitRTTIME' => '200ms' }) }
    it { is_expected.to allow_value({ 'LimitRTTIME' => '1s:10s' }) }
    it { is_expected.not_to allow_value({ 'LimitRTTIME' => 'bad' }) }
  end

  # === Process scheduling and priority ===
  context 'Nice=' do
    it { is_expected.to allow_value({ 'Nice' => -20 }) }
    it { is_expected.to allow_value({ 'Nice' => 0 }) }
    it { is_expected.to allow_value({ 'Nice' => 19 }) }
    it { is_expected.not_to allow_value({ 'Nice' => 20 }) }
    it { is_expected.not_to allow_value({ 'Nice' => '0' }) }
  end

  context 'IOSchedulingClass=' do
    it { is_expected.to allow_value({ 'IOSchedulingClass' => 'best-effort' }) }
    it { is_expected.to allow_value({ 'IOSchedulingClass' => 'realtime' }) }
    it { is_expected.to allow_value({ 'IOSchedulingClass' => 'idle' }) }
    it { is_expected.to allow_value({ 'IOSchedulingClass' => '' }) }
    it { is_expected.not_to allow_value({ 'IOSchedulingClass' => 'random' }) }
  end

  context 'IOSchedulingPriority=' do
    it { is_expected.to allow_value({ 'IOSchedulingPriority' => 0 }) }
    it { is_expected.to allow_value({ 'IOSchedulingPriority' => 7 }) }
    it { is_expected.to allow_value({ 'IOSchedulingPriority' => '' }) }
    it { is_expected.not_to allow_value({ 'IOSchedulingPriority' => 8 }) }
    it { is_expected.not_to allow_value({ 'IOSchedulingPriority' => '0' }) }
  end

  context 'OOMScoreAdjust=' do
    it { is_expected.to allow_value({ 'OOMScoreAdjust' => 0 }) }
    it { is_expected.to allow_value({ 'OOMScoreAdjust' => -1000 }) }
    it { is_expected.to allow_value({ 'OOMScoreAdjust' => 1000 }) }
    it { is_expected.not_to allow_value({ 'OOMScoreAdjust' => 1001 }) }
  end

  # === User, group, and identity ===
  context 'User=' do
    it { is_expected.to allow_value({ 'User' => 'root' }) }
    it { is_expected.to allow_value({ 'User' => 'myservice' }) }
    it { is_expected.not_to allow_value({ 'User' => '' }) }
  end

  context 'Group=' do
    it { is_expected.to allow_value({ 'Group' => 'root' }) }
    it { is_expected.not_to allow_value({ 'Group' => '' }) }
  end

  context 'DynamicUser=' do
    it { is_expected.to allow_value({ 'DynamicUser' => true }) }
    it { is_expected.to allow_value({ 'DynamicUser' => false }) }
    it { is_expected.not_to allow_value({ 'DynamicUser' => 'maybe' }) }
  end

  context 'SupplementaryGroups=' do
    it { is_expected.to allow_value({ 'SupplementaryGroups' => 'one' }) }
    it { is_expected.to allow_value({ 'SupplementaryGroups' => %w[one two] }) }
    it { is_expected.to allow_value({ 'SupplementaryGroups' => '' }) }
    it { is_expected.to allow_value({ 'SupplementaryGroups' => [''] }) }
    it { is_expected.to allow_value({ 'SupplementaryGroups' => ['', 'reset'] }) }
    it { is_expected.not_to allow_value({ 'SupplementaryGroups' => [] }) }
  end

  context 'SetLoginEnvironment=' do
    it { is_expected.to allow_value({ 'SetLoginEnvironment' => true }) }
    it { is_expected.to allow_value({ 'SetLoginEnvironment' => false }) }
  end

  context 'PAMName=' do
    it { is_expected.to allow_value({ 'PAMName' => 'login' }) }
    it { is_expected.to allow_value({ 'PAMName' => '' }) }
  end

  context 'KeyringMode=' do
    it { is_expected.to allow_value({ 'KeyringMode' => 'inherit' }) }
    it { is_expected.to allow_value({ 'KeyringMode' => 'private' }) }
    it { is_expected.to allow_value({ 'KeyringMode' => 'shared' }) }
    it { is_expected.not_to allow_value({ 'KeyringMode' => 'other' }) }
  end

  context 'UMask=' do
    it { is_expected.to allow_value({ 'UMask' => '0022' }) }
    it { is_expected.to allow_value({ 'UMask' => '077' }) }
    it { is_expected.not_to allow_value({ 'UMask' => '00022' }) }
  end

  # === Paths and directories ===
  context 'WorkingDirectory=' do
    it { is_expected.to allow_value({ 'WorkingDirectory' => '/var/lib/here' }) }
    it { is_expected.to allow_value({ 'WorkingDirectory' => '-/var/lib/here' }) }
    it { is_expected.to allow_value({ 'WorkingDirectory' => '~' }) }
    it { is_expected.to allow_value({ 'WorkingDirectory' => '' }) }
  end

  context 'RootDirectory=' do
    it { is_expected.to allow_value({ 'RootDirectory' => '/mnt/chroot' }) }
    it { is_expected.to allow_value({ 'RootDirectory' => '%h/.local/share/chroot' }) }
    it { is_expected.not_to allow_value({ 'RootDirectory' => 'relative' }) }
  end

  context 'RootImage=' do
    it { is_expected.to allow_value({ 'RootImage' => '/var/lib/image.raw' }) }
    it { is_expected.to allow_value({ 'RootImage' => '%h/.local/share/image.raw' }) }
    it { is_expected.not_to allow_value({ 'RootImage' => 'image.raw' }) }
  end

  context 'RootImageOptions=' do
    it { is_expected.to allow_value({ 'RootImageOptions' => 'ro' }) }
    it { is_expected.to allow_value({ 'RootImageOptions' => '' }) }
  end

  context 'RootEphemeral=' do
    it { is_expected.to allow_value({ 'RootEphemeral' => true }) }
    it { is_expected.to allow_value({ 'RootEphemeral' => false }) }
  end

  context 'RootHash=' do
    it { is_expected.to allow_value({ 'RootHash' => 'abc123' }) }
    it { is_expected.to allow_value({ 'RootHash' => '' }) }
  end

  context 'ProtectProc=' do
    %w[noaccess invisible ptraceable default].each do |val|
      it { is_expected.to allow_value({ 'ProtectProc' => val }) }
    end
    it { is_expected.not_to allow_value({ 'ProtectProc' => 'all' }) }
  end

  %w[RuntimeDirectory StateDirectory LogsDirectory CacheDirectory].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '/var/lib/service' }) }
      it { is_expected.to allow_value({ key => 'myservice' }) }
    end
  end

  context 'RuntimeDirectoryMode= and LogsDirectoryMode=' do
    it { is_expected.to allow_value({ 'RuntimeDirectoryMode' => '0750' }) }
    it { is_expected.to allow_value({ 'LogsDirectoryMode' => '0700' }) }
  end

  %w[BindPaths BindReadOnlyPaths].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '/src' }) }
      it { is_expected.to allow_value({ key => ['/src', '/dst'] }) }
      it { is_expected.to allow_value({ key => '-/src' }) }
      it { is_expected.to allow_value({ key => '%h/.local/share/src' }) }
      it { is_expected.to allow_value({ key => ['-%h/.local/share/src', '/dst'] }) }
      it { is_expected.not_to allow_value({ key => 'src' }) }
    end
  end

  context 'TemporaryFileSystem=' do
    it { is_expected.to allow_value({ 'TemporaryFileSystem' => '/tmp:size=5k,nr_inodes=1k,mode=1777' }) }
    it { is_expected.to allow_value({ 'TemporaryFileSystem' => ['/tmp:size=5k'] }) }
  end

  %w[ReadWritePaths ReadOnlyPaths InaccessiblePaths ExecPaths NoExecPaths].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => '+/var/log' }) }
      it { is_expected.to allow_value({ key => ['-/var/log', '+/opt/', '-+/home'] }) }
      it { is_expected.to allow_value({ key => '+%h/.local/share' }) }
      it { is_expected.to allow_value({ key => ['-%h/.local/share', '+%h/.cache', '-+%h/.config'] }) }
      it { is_expected.not_to allow_value({ key => 'foo bar blub' }) }
      it { is_expected.not_to allow_value({ key => '+-/opt' }) }
    end
  end

  # === Security and isolation ===
  context 'ProtectSystem=' do
    it { is_expected.to allow_value({ 'ProtectSystem' => true }) }
    it { is_expected.to allow_value({ 'ProtectSystem' => false }) }
    it { is_expected.to allow_value({ 'ProtectSystem' => 'full' }) }
    it { is_expected.to allow_value({ 'ProtectSystem' => 'strict' }) }
    it { is_expected.not_to allow_value({ 'ProtectSystem' => 'partial' }) }
  end

  context 'ProtectHome=' do
    it { is_expected.to allow_value({ 'ProtectHome' => true }) }
    it { is_expected.to allow_value({ 'ProtectHome' => false }) }
    it { is_expected.to allow_value({ 'ProtectHome' => 'read-only' }) }
    it { is_expected.to allow_value({ 'ProtectHome' => 'tmpfs' }) }
    it { is_expected.not_to allow_value({ 'ProtectHome' => 'strict' }) }
  end

  %w[
    MountAPIVFS PrivateTmp PrivateDevices PrivateNetwork PrivateIPC PrivatePIDs
    PrivateUsers ProtectHostname ProtectClock ProtectKernelTunables
    ProtectKernelModules ProtectKernelLogs ProtectControlGroups
    PrivateBPF LockPersonality MemoryDenyWriteExecute
    RestrictRealtime RestrictSUIDSGID RemoveIPC PrivateMounts
    NoNewPrivileges
  ].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => true }) }
      it { is_expected.to allow_value({ key => false }) }
      it { is_expected.not_to allow_value({ key => 'yes' }) }
    end
  end

  context 'NetworkNamespacePath=' do
    it { is_expected.to allow_value({ 'NetworkNamespacePath' => '/var/run/netns/mynamespace' }) }
    it { is_expected.to allow_value({ 'NetworkNamespacePath' => '%t/netns/mynamespace' }) }
    it { is_expected.not_to allow_value({ 'NetworkNamespacePath' => 'relative' }) }
  end

  context 'CapabilityBoundingSet=' do
    it { is_expected.to allow_value({ 'CapabilityBoundingSet' => 'CAP_NET_ADMIN' }) }
    it { is_expected.to allow_value({ 'CapabilityBoundingSet' => %w[CAP_NET_ADMIN CAP_SYS_PTRACE] }) }
    it { is_expected.to allow_value({ 'CapabilityBoundingSet' => '' }) }
  end

  context 'AmbientCapabilities=' do
    it { is_expected.to allow_value({ 'AmbientCapabilities' => '' }) }
    it { is_expected.to allow_value({ 'AmbientCapabilities' => 'CAP_NET_BIND_SERVICE' }) }
    it { is_expected.to allow_value({ 'AmbientCapabilities' => ['CAP_NET_BIND_SERVICE'] }) }
    it { is_expected.to allow_value({ 'AmbientCapabilities' => ['', 'CAP_NET_BIND_SERVICE'] }) }
    it { is_expected.not_to allow_value({ 'AmbientCapabilities' => 'cap_net_bind_service' }) }
  end

  context 'RestrictAddressFamilies=' do
    it { is_expected.to allow_value({ 'RestrictAddressFamilies' => 'AF_INET' }) }
    it { is_expected.to allow_value({ 'RestrictAddressFamilies' => %w[AF_INET AF_INET6] }) }
    it { is_expected.to allow_value({ 'RestrictAddressFamilies' => 'none' }) }
    it { is_expected.not_to allow_value({ 'RestrictAddressFamilies' => 'AF_PACKET' }) }
  end

  context 'RestrictNamespaces=' do
    it { is_expected.to allow_value({ 'RestrictNamespaces' => true }) }
    it { is_expected.to allow_value({ 'RestrictNamespaces' => false }) }
    it { is_expected.to allow_value({ 'RestrictNamespaces' => 'net' }) }
    it { is_expected.to allow_value({ 'RestrictNamespaces' => %w[net mnt] }) }
    it { is_expected.not_to allow_value({ 'RestrictNamespaces' => 'all' }) }
  end

  context 'SystemCallFilter=' do
    it { is_expected.to allow_value({ 'SystemCallFilter' => '@system-service' }) }
    it { is_expected.to allow_value({ 'SystemCallFilter' => %w[read write] }) }
  end

  context 'SystemCallErrorNumber=' do
    it { is_expected.to allow_value({ 'SystemCallErrorNumber' => 'EPERM' }) }
  end

  context 'SystemCallArchitectures=' do
    it { is_expected.to allow_value({ 'SystemCallArchitectures' => 'native' }) }
    it { is_expected.to allow_value({ 'SystemCallArchitectures' => %w[native x86-64] }) }
  end

  # === Environment and logging ===
  context 'Environment=' do
    it { is_expected.to allow_value({ 'Environment' => '' }) }
    it { is_expected.to allow_value({ 'Environment' => 'FOO=BAR' }) }
    it { is_expected.to allow_value({ 'Environment' => ['FOO=BAR', 'BAR=FOO'] }) }
  end

  context 'EnvironmentFile=' do
    it { is_expected.to allow_value({ 'EnvironmentFile' => '/etc/sysconfig/foo' }) }
    it { is_expected.to allow_value({ 'EnvironmentFile' => '-/etc/sysconfig/foo' }) }
    it { is_expected.to allow_value({ 'EnvironmentFile' => ['/etc/sysconfig/foo', '-/etc/sysconfig/foo-bar'] }) }
    it { is_expected.to allow_value({ 'EnvironmentFile' => '%h/.config/myapp/env' }) }
    it { is_expected.to allow_value({ 'EnvironmentFile' => '-%h/.config/myapp/env' }) }
    it { is_expected.to allow_value({ 'EnvironmentFile' => ['%h/.config/myapp/env', '-%h/.config/myapp/env'] }) }
    it { is_expected.not_to allow_value({ 'EnvironmentFile' => '-/' }) }
    it { is_expected.not_to allow_value({ 'EnvironmentFile' => 'relative-path.sh' }) }
  end

  context 'StandardInput=' do
    it { is_expected.to allow_value({ 'StandardInput' => 'null' }) }
    it { is_expected.to allow_value({ 'StandardInput' => 'tty' }) }
    it { is_expected.to allow_value({ 'StandardInput' => 'socket' }) }
    it { is_expected.to allow_value({ 'StandardInput' => 'file:/tmp/inputfile' }) }
    it { is_expected.to allow_value({ 'StandardInput' => 'fd:myfd' }) }
    it { is_expected.not_to allow_value({ 'StandardInput' => '/tmp/inputfile' }) }
  end

  context 'StandardOutput= and StandardError=' do
    %w[StandardOutput StandardError].each do |key|
      it { is_expected.to allow_value({ key => 'null' }) }
      it { is_expected.to allow_value({ key => 'journal' }) }
      it { is_expected.to allow_value({ key => 'kmsg+console' }) }
      it { is_expected.to allow_value({ key => 'file:/var/log/service.log' }) }
      it { is_expected.to allow_value({ key => 'append:/var/log/service.log' }) }
    end
  end

  context 'LogLevelMax=' do
    %w[emerg alert crit err warning notice info debug].each do |val|
      it { is_expected.to allow_value({ 'LogLevelMax' => val }) }
    end
    it { is_expected.not_to allow_value({ 'LogLevelMax' => 'top' }) }
  end

  context 'LogRateLimitIntervalSec=' do
    it { is_expected.to allow_value({ 'LogRateLimitIntervalSec' => '30s' }) }
    it { is_expected.to allow_value({ 'LogRateLimitIntervalSec' => '0' }) }
    it { is_expected.to allow_value({ 'LogRateLimitIntervalSec' => '500ms' }) }
  end

  context 'LogRateLimitBurst=' do
    it { is_expected.to allow_value({ 'LogRateLimitBurst' => 0 }) }
    it { is_expected.to allow_value({ 'LogRateLimitBurst' => 1000 }) }
  end

  context 'SyslogIdentifier=' do
    it { is_expected.to allow_value({ 'SyslogIdentifier' => 'myservice' }) }
    it { is_expected.not_to allow_value({ 'SyslogIdentifier' => %w[a b] }) }
  end

  # === Credentials ===
  %w[LoadCredential LoadCredentialEncrypted SetCredential SetCredentialEncrypted].each do |key|
    context "#{key}=" do
      it { is_expected.to allow_value({ key => 'mykey:/etc/secret' }) }
      it { is_expected.to allow_value({ key => ['key1:/etc/s1', 'key2:/etc/s2'] }) }
      it { is_expected.to allow_value({ key => '' }) }
    end
  end

  # Deprecated options
  context 'MemoryLimit=' do
    it { is_expected.not_to allow_value({ 'MemoryLimit' => '50%' }) }
    it { is_expected.to allow_value({ 'MemoryLimit' => '512M' }) }
    it { is_expected.to allow_value({ 'MemoryLimit' => 'infinity' }) }
  end

  # systemd.resource-control
  it_behaves_like 'systemd_resource_control'
end
