require 'spec_helper'
require './lib/robust_client_socket/configuration.rb'

RSpec.describe RobustClientSocket::Configuration do
  let(:dummy_class) { Class.new { extend RobustClientSocket::Configuration } }

  before { allow(dummy_class).to receive(:correct_configuration?).and_return(true) }

  describe '#configure' do
    it 'yields the configuration object to the block' do
      dummy_class.configure do |config|
        expect(config).to be_a(RobustClientSocket::ConfigStore)
      end
    end

    it 'sets the configured flag to true' do
      dummy_class.configure { |config| }
      expect(dummy_class.configured?).to eq(true)
    end
  end

  describe '#configured?' do
    it 'returns false if not configured' do
      expect(dummy_class.configured?).to eq(false)
    end

    it 'returns true if configured' do
      dummy_class.configure { |config| }
      expect(dummy_class.configured?).to eq(true)
    end
  end

  describe '#correct_configuration?' do
    before { allow(dummy_class).to receive(:correct_configuration?).and_call_original }

    it 'returns false if services is empty' do
      dummy_class.configure { |config| }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns false if creds is missing base_uri' do
      dummy_class.configure { |config| config.service = { public_key: 'public_key' } }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns false if creds is missing public_key' do
      dummy_class.configure { |config| config.service = { base_uri: 'base_uri' } }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns true if creds is correct' do
      dummy_class.configure { |config| config.client_name = 'sample'; config.service = { base_uri: 'base_uri', public_key: 'public_key' } }
      expect(dummy_class.correct_configuration?).to eq(true)
    end
  end
end

RSpec.describe RobustClientSocket::ConfigStore do
  subject(:config_store) { described_class.new }

  it 'has attribute keychain' do
    config_store.service = { uri: 'uri' }
    expect(config_store.services).to eq({ service: { uri: 'uri' } })
  end
end
