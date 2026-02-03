require 'spec_helper'
require './lib/robust_client_socket/configuration.rb'

RSpec.describe RobustClientSocket::Configuration do
  let(:dummy_class) { Class.new { extend RobustClientSocket::Configuration } }

  before { allow(dummy_class).to receive(:correct_configuration?).and_return(true) }

  describe '#configure' do
    let(:public_key) { OpenSSL::PKey::RSA.generate(2048).public_key.to_pem }

    it 'yields the configuration object to the block' do
      dummy_class.configure do |config|
        config.client_name = 'test'
        config.service = { base_uri: 'https://example.com', public_key: public_key }
        expect(config).to be_a(RobustClientSocket::ConfigStore)
      end
    end

    it 'sets the configured flag to true' do
      dummy_class.configure do |config|
        config.client_name = 'test'
        config.service = { base_uri: 'https://example.com', public_key: public_key }
      end
      expect(dummy_class.configured?).to eq(true)
    end

    context 'with invalid key size' do
      let(:small_key) { OpenSSL::PKey::RSA.generate(1024).public_key.to_pem }

      it 'raises SecurityError' do
        expect {
          dummy_class.configure do |config|
            config.client_name = 'test'
            config.service = { base_uri: 'https://example.com', public_key: small_key }
          end
        }.to raise_error(SecurityError, /below minimum/)
      end
    end
  end

  describe '#configured?' do
    let(:public_key) { OpenSSL::PKey::RSA.generate(2048).public_key.to_pem }

    it 'returns false if not configured' do
      expect(dummy_class.configured?).to eq(false)
    end

    it 'returns true if configured' do
      dummy_class.configure do |config|
        config.client_name = 'test'
        config.service = { base_uri: 'https://example.com', public_key: public_key }
      end
      expect(dummy_class.configured?).to eq(true)
    end
  end

  describe '#correct_configuration?' do
    let(:public_key) { OpenSSL::PKey::RSA.generate(2048).public_key.to_pem }

    before { allow(dummy_class).to receive(:correct_configuration?).and_call_original }

    it 'returns false if services is empty' do
      dummy_class.configure { |config| }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns false if creds is missing base_uri' do
      dummy_class.configure { |config| config.service = { public_key: public_key } }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns false if creds is missing public_key' do
      dummy_class.configure { |config| config.service = { base_uri: 'base_uri' } }
      expect(dummy_class.correct_configuration?).to eq(false)
    end

    it 'returns true if creds is correct' do
      dummy_class.configure do |config|
        config.client_name = 'sample'
        config.service = { base_uri: 'base_uri', public_key: public_key }
      end
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

  describe '#initialize' do
    it 'initializes services as empty hash' do
      expect(config_store.services).to eq({})
    end

    it 'initializes client_name as nil' do
      expect(config_store.client_name).to be_nil
    end
  end

  describe '#method_missing' do
    context 'with setter method' do
      it 'adds service to services hash' do
        config_store.api_service = { base_uri: 'https://api.example.com', public_key: 'key' }
        expect(config_store.services[:api_service]).to eq({ base_uri: 'https://api.example.com', public_key: 'key' })
      end

      it 'rejects non-hash values' do
        config_store.api_service = 'string_value'
        expect(config_store.services[:api_service]).to be false
      end
    end
  end

  describe 'accessors' do
    it 'allows setting client_name' do
      config_store.client_name = 'test_client'
      expect(config_store.client_name).to eq('test_client')
    end

    it 'allows setting header_name' do
      config_store.header_name = 'Custom-Header'
      expect(config_store.header_name).to eq('Custom-Header')
    end
  end
end
