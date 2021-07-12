# Systemd

[![Build Status](https://github.com/voxpupuli/puppet-systemd/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-systemd/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-systemd/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-systemd/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/systemd.svg)](https://forge.puppetlabs.com/puppet/systemd)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/systemd.svg)](https://forge.puppetlabs.com/puppet/systemd)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/systemd.svg)](https://forge.puppetlabs.com/puppet/systemd)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/systemd.svg)](https://forge.puppetlabs.com/puppet/systemd)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-systemd)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-systemd.svg)](LICENSE)
[![Donated by Camptocamp](https://img.shields.io/badge/donated%20by-camptocamp-fb7047.svg)](#transfer-notice)


## Overview

This module declares exec resources to create global sync points for reloading systemd.

**Version 2 and newer of the module don't work with Hiera 3! You need to migrate your existing Hiera setup to Hiera 5**

## Usage and examples

There are two ways to use this module.

### unit files

Let this module handle file creation.

```puppet
systemd::unit_file { 'foo.service':
 source => "puppet:///modules/${module_name}/foo.service",
}
~> service {'foo':
  ensure => 'running',
}
```

This is equivalent to:

```puppet
file { '/usr/lib/systemd/system/foo.service':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => "puppet:///modules/${module_name}/foo.service",
}
~> service {'foo':
  ensure => 'running',
}
```

You can also use this module to more fully manage the new unit. This example deploys the unit, reloads systemd and then enables and starts it.

```puppet
systemd::unit_file { 'foo.service':
 source => "puppet:///modules/${module_name}/foo.service",
 enable => true,
 active => true,
}
```

### drop-in files

Drop-in files are used to add or alter settings of a unit without modifying the
unit itself. As for the unit files, the module can handle the file and
directory creation:

```puppet
systemd::dropin_file { 'foo.conf':
  unit   => 'foo.service',
  source => "puppet:///modules/${module_name}/foo.conf",
}
~> service {'foo':
  ensure    => 'running',
}
```

This is equivalent to:

```puppet
file { '/etc/systemd/system/foo.service.d':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
}

file { '/etc/systemd/system/foo.service.d/foo.conf':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => "puppet:///modules/${module_name}/foo.conf",
}
~> service {'foo':
  ensure => 'running',
}
```

dropin-files can also be generated via hiera:

```yaml
systemd::dropin_files:
  my-foo.conf:
    unit: foo.service
    source: puppet:///modules/${module_name}/foo.conf
```

### tmpfiles

Let this module handle file creation and systemd reloading

```puppet
systemd::tmpfile { 'foo.conf':
  source => "puppet:///modules/${module_name}/foo.conf",
}
```

Or handle file creation yourself and trigger systemd.

```puppet
include systemd::tmpfiles

file { '/etc/tmpfiles.d/foo.conf':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => "puppet:///modules/${module_name}/foo.conf",
}
~> Class['systemd::tmpfiles']
```

### timer units
Create a systemd timer unit and a systemd service unit to execute from
that timer

The following will create a timer unit and a service unit file.
When `active` and `enable` are set to `true` the puppet service `runoften.timer` will be
declared, started and enabled.

```puppet
systemd::timer{'runoften.timer':
  timer_source   => "puppet:///modules/${module_name}/runoften.timer",
  service_source => "puppet:///modules/${module_name}/runoften.service",
  active         => true,
  enable         => true,
}
```

A trivial daily run.
In this case enable and active are both unset and so the service `daily.timer`
is not declared by the `systemd::timer` type.

```puppet
$_timer = @(EOT)
[Timer]
OnCalendar=daily
RandomizedDelaySec=1d
EOT

$_service = @(EOT)
[Service]
Type=oneshot
ExecStart=/usr/bin/touch /tmp/file
EOT

systemd::timer{'daily.timer':
  timer_content   => $_timer,
  service_content => $_service,
}

service{'daily.timer':
  ensure    => running,
  subscribe => Systemd::Timer['daily.timer'],
}

```

If neither `service_content` or `service_source` are specified then no
service unit will be created.

The service unit name can also be specified.

```puppet
$_timer = @(EOT)
[Timer]
OnCalendar=daily
RandomizedDelaySec=1d
Unit=touch-me-today.service
EOT

$_service = @(EOT)
[Service]
Type=oneshot
ExecStart=/usr/bin/touch /tmp/file
EOT


systemd::timer{'daily.timer':
  timer_content   => $_timer,
  service_unit    => 'touch-me-today.service',
  service_content => $_service,
  active          => true,
  enable          => true,
}
```

### service limits

Manage soft and hard limits on various resources for executed processes.

```puppet
systemd::service_limits { 'foo.service':
  limits => {
    'LimitNOFILE' => 8192,
    'LimitNPROC'  => 16384,
  }
}
```

Or provide the configuration file yourself. Systemd reloading and restarting of the service are handled by the module.

```puppet
systemd::service_limits { 'foo.service':
  source => "puppet:///modules/${module_name}/foo.conf",
}
```

### Daemon reloads

Systemd caches unit files and their relations. This means it needs to reload, typically done via `systemctl daemon-reload`. Since Puppet 6.1.0 ([PUP-3483](https://tickets.puppetlabs.com/browse/PUP-3483)) takes care of this by calling `systemctl show $SERVICE -- --property=NeedDaemonReload` to determine if a reload is needed. Typically this works well and removes the need for `systemd::systemctl::daemon_reload` as provided prior to camptocamp/systemd 3.0.0. This avoids common circular dependencies.

It does contain a workaround for [PUP-9473](https://tickets.puppetlabs.com/browse/PUP-9473) but there's no guarantee that this works in every case.

### network

systemd-networkd is able to manage your network configuration. We provide a
defined resource which can write the interface configurations. systemd-networkd
needs to be restarted to apply the configs. The defined resource can do this
for you:

```puppet
systemd::network{'eth0.network':
  source          => "puppet:///modules/${module_name}/eth0.network",
  restart_service => true,
}
```

### Services

Systemd provides multiple services. Currently you can manage `systemd-resolved`,
`systemd-timesyncd`, `systemd-networkd`, `systemd-journald` and `systemd-logind`
via the main class:

```puppet
class{'systemd':
  manage_resolved  => true,
  manage_networkd  => true,
  manage_timesyncd => true,
  manage_journald  => true,
  manage_udevd     => true,
  manage_logind    => true,
}
```

$manage_networkd is required if you want to reload it for new
`systemd::network` resources. Setting $manage_resolved will also manage your
`/etc/resolv.conf`.

When configuring `systemd::resolved` you could set `dns_stub_resolver` to false (default) to use a *standard* `/etc/resolved.conf`, or you could set it to `true` to use the local resolver provided by `systemd-resolved`.

Systemd has introduced `DNS Over TLS` in the release 239. Currently three states are supported `yes` (since systemd 243), `opportunistic` (true) and `no` (false, default). When enabled with `yes` or `opportunistic` `systemd-resolved` will start a TCP-session to a DNS server with `DNS Over TLS` support. When enabled with `yes` (strict mode), queries will fail if the configured DNS servers do not support `DNS Over TLS`. Note that there will be no host checking for `DNS Over TLS` due to missing implementation in `systemd-resolved`.

It is possible to configure the default ntp servers in `/etc/systemd/timesyncd.conf`:

```puppet
class{'systemd':
  manage_timesyncd    => true,
  ntp_server          => ['0.pool.ntp.org', '1.pool.ntp.org'],
  fallback_ntp_server => ['2.pool.ntp.org', '3.pool.ntp.org'],
}
```

This requires [puppetlabs-inifile](https://forge.puppet.com/puppetlabs/inifile), which is only a soft dependency in this module (you need to explicitly install it). Both parameters accept a string or an array.

### Resource Accounting

Systemd has support for different accounting option. It can track
CPU/Memory/Network stats per process. This is explained in depth at [systemd-system.conf](https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html).
This defaults to off (default on most operating systems). You can enable this
with the `$manage_accounting` parameter. The module provides a default set of
working accounting options per operating system, but you can still modify them
with `$accounting`:

```puppet
class{'systemd':
  manage_accounting => true,
  accounting        => {
    'DefaultCPUAccounting'    => 'yes',
    'DefaultMemoryAccounting' => 'no',
  }
}
```
### journald configuration

It also allows you to manage journald settings. You can manage journald settings through setting the `journald_settings` parameter. If you want a parameter to be removed, you can pass its value as params.

```yaml
systemd::journald_settings:
  Storage: auto
  MaxRetentionSec: 5day
  MaxLevelStore:
    ensure: absent
```

### udevd configuration

It allows you to manage the udevd configuration.  You can set the udev.conf values via the `udev_log`, `udev_children_max`, `udev_exec_delay`, `udev_event_timeout`, `udev_resolve_names`, and `udev_timeout_signal` parameters.

Additionally you can set custom udev rules with the `udev_rules` parameter.

```puppet
class { 'systemd':
  manage_udevd => true,
  udev_rules   => {
      'example_raw.rules' => {
      'rules'             => [
        'ACTION=="add", KERNEL=="sda", RUN+="/bin/raw /dev/raw/raw1 %N"',
        'ACTION=="add", KERNEL=="sdb", RUN+="/bin/raw /dev/raw/raw2 %N"',
      ],
    },
  },
}
```

### udev::rules configuration

Custom udev rules can be defined for specific events.

```yaml
systemd::udev::rule:
  ensure: present
  path: /etc/udev/rules.d
  selinux_ignore_defaults: false
  notify: "Service[systemd-udevd']"
  rules:
    - 'ACTION=="add", KERNEL=="sda", RUN+="/bin/raw /dev/raw/raw1 %N"'
    - 'ACTION=="add", KERNEL=="sdb", RUN+="/bin/raw /dev/raw/raw2 %N"',
```

### logind configuration

It also allows you to manage logind settings. You can manage logind settings through setting the `logind_settings` parameter. If you want a parameter to be removed, you can pass its value as params.

```yaml
systemd::logind_settings:
  HandleSuspendKey: 'ignore'
  KillUserProcesses: 'no'
  RemoveIPC:
    ensure: absent
  UserTasksMax: 10000
```

### User linger

A `loginctl_user` resource is available to manage user linger enablement:

```puppet
loginctl_user { 'foo':
  linger => enabled,
}
```

or as a hash via the `systemd::loginctl_users` parameter.


## Transfer Notice

This plugin was originally authored by [Camptocamp](http://www.camptocamp.com).
The maintainer preferred that Puppet Community take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here instead of Camptocamp.

Previously: https://github.com/camptocamp/puppet-systemd
