# frozen_string_literal: true

require 'spec_helper'

describe 'Systemd::Unit::Automount' do
  context 'with a key of Where can have a path to mount on' do
    it { is_expected.to allow_value({ 'Where' => '/mnt/foo' }) }
    it { is_expected.to allow_value({ 'Where' => '%h/mnt/foo' }) }
    it { is_expected.not_to allow_value({ 'Where' => 'mnt/foo' }) }
    it { is_expected.not_to allow_value({ 'Where' => '' }) }
  end

  context 'with a key of TimeoutIdleSec' do
    it { is_expected.to allow_value({ 'TimeoutIdleSec' => '10min' }) }
  end
end
