require 'spec_helper'

describe Facter.fact(:systemd_version) do
  before do
    Facter.clear
  end

  describe 'systemd_version' do
    context 'returns version when systemd fact present' do
      before do
        allow(Facter.fact(:systemd)).to receive(:value).and_return(true)
      end
      let(:facts) { { systemd: true } }

      it do
        expect(Facter::Util::Resolution).to receive(:exec).with("systemctl --version | awk '/systemd/{ print $2 }'").and_return('229') # rubocop:disable RSpec/MessageSpies
        expect(Facter.value(:systemd_version)).to eq('229')
      end
    end
    context 'returns nil when systemd fact not present' do
      before do
        allow(Facter.fact(:systemd)).to receive(:value).and_return(false)
      end
      let(:facts) { { systemd: false } }

      it do
        expect(Facter::Util::Resolution).not_to receive(:exec).with("systemctl --version | awk '/systemd/{ print $2 }'") # rubocop:disable RSpec/MessageSpies
        expect(Facter.value(:systemd_version)).to eq(nil)
      end
    end
  end
end
