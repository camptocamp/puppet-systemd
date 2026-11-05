# frozen_string_literal: true

require 'spec_helper'

describe Facter.fact(:systemd_machine_info) do
  before do
    Facter.clear
  end

  after do
    Facter.clear
  end

  describe 'systemd_machine_info' do
    context 'returns machine info when systemd present' do
      let(:json_output) do
        '{"Hostname":"server01.example.com","Chassis":"desktop","Deployment":"production","Location":"Data Center","MachineInformationData":["CHASSIS=desktop","DEPLOYMENT=production","LOCATION=Data Center","TAGS=production:x86_64:team=enterprise"]}'
      end

      before do
        allow(Facter.fact(:systemd)).to receive(:value).and_return(true)
      end

      it 'parses JSON output correctly' do
        allow(Facter::Core::Execution).to receive(:execute).with('hostnamectl --json=short 2>/dev/null').and_return(json_output)
        result = Facter.value(:systemd_machine_info)
        expect(result).to be_a(Hash)
        expect(result['CHASSIS']).to eq('desktop')
        expect(result['DEPLOYMENT']).to eq('production')
        expect(result['TAGS']).to eq(['production', 'team=enterprise', 'x86_64'])
      end

      it 'sorts TAGS array' do
        allow(Facter::Core::Execution).to receive(:execute).with('hostnamectl --json=short 2>/dev/null').and_return(json_output)
        result = Facter.value(:systemd_machine_info)
        expect(result['TAGS']).to eq(['production', 'team=enterprise', 'x86_64'])
      end
    end

    context 'returns nil when hostnamectl fails' do
      before do
        allow(Facter.fact(:systemd)).to receive(:value).and_return(true)
      end

      it 'handles missing hostnamectl' do
        allow(Facter::Core::Execution).to receive(:execute).with('hostnamectl --json=short 2>/dev/null').and_return('')
        expect(Facter.value(:systemd_machine_info)).to be_nil
      end
    end

    context 'returns nil when systemd not present' do
      before do
        allow(Facter.fact(:systemd)).to receive(:value).and_return(false)
      end

      it 'does not execute hostnamectl' do
        expect(Facter::Core::Execution).not_to receive(:execute)
        expect(Facter.value(:systemd_machine_info)).to be_nil
      end
    end
  end
end
