require 'spec_helper'
require 'httparty'
require './lib/robust_client_socket/http/helpers'
require './lib/robust_client_socket/http/httparty_overrides'
require './lib/robust_client_socket/http/client'

RSpec.describe RobustClientSocket::HTTP::Client do
  let(:credentials) do
    {
      base_uri: 'https://example.com',
      public_key: OpenSSL::PKey::RSA.new(2048).public_key.to_s
    }
  end
  let(:client_name) { 'test_client' }
  let(:header_name) { 'Custom-Token' }

  describe '.init' do
    context 'with valid HTTPS credentials' do
      it 'sets credentials' do
        described_class.init(credentials: credentials, client_name: client_name)
        expect(described_class.credentials).to eq(credentials)
      end

      it 'sets client_name' do
        described_class.init(credentials: credentials, client_name: client_name)
        expect(described_class.client_name).to eq(client_name)
      end

      it 'sets custom header_name' do
        described_class.init(credentials: credentials, client_name: client_name, header_name: header_name)
        expect(described_class.header_name).to eq(header_name)
      end

      it 'sets base_uri' do
        described_class.init(credentials: credentials, client_name: client_name)
        expect(described_class.base_uri).to eq('https://example.com')
      end

      it 'forces SSL verification' do
        described_class.init(credentials: credentials, client_name: client_name)
        expect(described_class.default_options[:verify]).to be true
        expect(described_class.default_options[:verify_mode]).to eq(OpenSSL::SSL::VERIFY_PEER)
      end
    end

    context 'in production with non-HTTPS base_uri' do
      let(:http_credentials) { credentials.merge(base_uri: 'http://example.com') }

      before do
        allow(RobustClientSocket::HTTP).to receive(:production?).and_return(true)
      end

      it 'raises SecurityError' do
        expect {
          described_class.init(credentials: http_credentials, client_name: client_name)
        }.to raise_error(SecurityError, 'HTTPS required in production')
      end
    end

    context 'in development with HTTP base_uri' do
      let(:http_credentials) { credentials.merge(base_uri: 'http://example.com') }

      before do
        allow(RobustClientSocket::HTTP).to receive(:production?).and_return(false)
      end

      it 'allows HTTP' do
        expect {
          described_class.init(credentials: http_credentials, client_name: client_name)
        }.not_to raise_error
      end
    end
  end
end

RSpec.describe RobustClientSocket::HTTP do
  describe '.production?' do
    context 'when Rails is defined' do
      let(:rails_stub) { double('Rails', production?: true) }
      
      before do
        stub_const('Rails', rails_stub)
      end

      it 'delegates to Rails.production?' do
        expect(described_class.production?).to be true
      end
    end

    context 'when Rails is not defined' do
      before do
        hide_const('Rails') if defined?(Rails)
      end

      it 'checks RACK_ENV for production' do
        allow(ENV).to receive(:fetch).with('RACK_ENV').and_return('production')
        expect(described_class.production?).to be true
      end

      it 'defaults to development' do
        allow(ENV).to receive(:fetch).with('RACK_ENV').and_yield
        expect(described_class.production?).to be false
      end
    end
  end
end
