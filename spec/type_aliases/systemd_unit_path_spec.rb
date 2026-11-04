# frozen_string_literal: true

require 'spec_helper'

describe 'Systemd::Unit::Path' do
  %w[PathExists PathExistsGlob PathChanged PathModified DirectoryNotEmpty].each do |assert|
    context "with a key of #{assert} can have values of a path" do
      it { is_expected.to allow_value({ assert => '' }) }
      it { is_expected.to allow_value({ assert => '/etc/passwd' }) }
      it { is_expected.to allow_value({ assert => '/etc/krb5.conf.d/*.conf' }) }
      it { is_expected.to allow_value({ assert => '%h/.config/myapp/config.json' }) }
      it { is_expected.to allow_value({ assert => ['', '/etc/group', '/etc/sssd/sssd.conf.d/*.conf'] }) }
      it { is_expected.to allow_value({ assert => ['', '%h/.config/myapp/config.json'] }) }
      it { is_expected.not_to allow_value({ assert => 'rc.d/rc.local' }) }
      it { is_expected.not_to allow_value({ assert => ['', 'var/run'] }) }
    end
  end

  %w[Unit].each do |assert|
    context "with a key of #{assert} can have values of a unit name" do
      it { is_expected.to allow_value({ assert => 'my.service' }) }
      it { is_expected.not_to allow_value({ assert => 'yours' }) }
    end
  end

  %w[MakeDirectory].each do |assert|
    context "with a key of #{assert} can have values of a boolean" do
      it { is_expected.to allow_value({ assert => false }) }
      it { is_expected.to allow_value({ assert => true }) }
      it { is_expected.not_to allow_value({ assert => 'yes' }) }
    end
  end

  %w[DirectoryMode].each do |assert|
    context "with a key of #{assert} can have values of a file permission" do
      it { is_expected.to allow_value({ assert => '0755' }) }
      it { is_expected.to allow_value({ assert => '700' }) }
      it { is_expected.not_to allow_value({ assert => 0o755 }) }
      it { is_expected.not_to allow_value({ assert => 755 }) }
      it { is_expected.not_to allow_value({ assert => 'u+s,g-s' }) }
    end
  end

  %w[TriggerLimitIntervalSec].each do |assert|
    context "with a key of #{assert} can have value of a time period" do
      it { is_expected.to allow_value({ assert => '' }) } # ? Not sure actually
      it { is_expected.to allow_value({ assert => '24hours' }) }
      it { is_expected.to allow_value({ assert => '1min 30s' }) }
      it { is_expected.not_to allow_value({ assert => ['', '1min 30s'] }) }
    end
  end

  %w[TriggerLimitBurst].each do |assert|
    context "with a key of #{assert} can have values of a count" do
      it { is_expected.to allow_value({ assert => 0 }) }
      it { is_expected.to allow_value({ assert => 10 }) }
      it { is_expected.not_to allow_value({ assert => '5' }) }
    end
  end
end
