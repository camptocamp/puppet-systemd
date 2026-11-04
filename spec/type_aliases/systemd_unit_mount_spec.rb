# frozen_string_literal: true

require 'spec_helper'
require 'type_aliases/shared_systemd_resource_control'

describe 'Systemd::Unit::Mount' do
  context 'with a key of What can have thing to mount' do
    it { is_expected.to allow_value({ 'What' => 'tmpfs' }) }
    it { is_expected.to allow_value({ 'What' => 'nfs://example.org/exports/home' }) }
    it { is_expected.to allow_value({ 'What' => '/dev/vda1' }) }
  end

  context 'with a key of Where can have a path to mount on' do
    it { is_expected.to allow_value({ 'Where' => '/mnt/foo' }) }
    it { is_expected.to allow_value({ 'Where' => '/mnt/foo/file.txt' }) }
    it { is_expected.to allow_value({ 'Where' => '%h/mnt/foo' }) }
    it { is_expected.not_to allow_value({ 'Where' => 'mnt/foo' }) }
  end

  context 'with a key of Type can have a path to mount on' do
    it { is_expected.to allow_value({ 'Type' => 'tmpfs' }) }
    it { is_expected.to allow_value({ 'Type' => 'ext2' }) }
  end

  context 'with a key of Options can have a path to mount on' do
    it { is_expected.to allow_value({ 'Options' => 'size=300M,mode=0700,uid=sssd,gid=sssd,root' }) }
  end

  context 'with a key of DirectoryMode can have a mode of' do
    it { is_expected.to allow_value({ 'DirectoryMode' => '0700' }) }
  end

  context 'with a key of TimeoutSec can have a mode of' do
    it { is_expected.to allow_value({ 'TimeoutSec' => '100' }) }
    it { is_expected.to allow_value({ 'TimeoutSec' => '5min 20s' }) }
    it { is_expected.to allow_value({ 'TimeoutSec' => '' }) }
  end

  %w[SloppyOptions LazyUnmount ReadWriteOnly ForceUnmount].each do |assert|
    context "with a key of #{assert} can have values of a path" do
      it { is_expected.to allow_value({ assert => false }) }
      it { is_expected.to allow_value({ assert => true }) }
    end
  end

  context 'with a key of OOMScoreAdjust' do
    it {
      is_expected.to allow_value({ 'OOMScoreAdjust' => 999 })
      is_expected.to allow_value({ 'OOMScoreAdjust' => -999 })
      is_expected.not_to allow_value({ 'OOMScoreAdjust' => 1005 })
      is_expected.not_to allow_value({ 'OOMScoreAdjust' => '10' })
    }
  end

  # systemd.resource-control
  it_behaves_like 'systemd_resource_control'
end
