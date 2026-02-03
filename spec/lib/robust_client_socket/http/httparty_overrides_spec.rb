require 'spec_helper'
require 'webmock/rspec'
require 'httparty'
require './lib/robust_client_socket/http/httparty_overrides'
require './lib/robust_client_socket/http/helpers'

RSpec.describe RobustClientSocket::HTTP::HTTPartyOverrides do
  let(:test_class) do
    Class.new do
      include HTTParty
      include RobustClientSocket::HTTP::Helpers
      include RobustClientSocket::HTTP::HTTPartyOverrides

      class << self
        attr_accessor :credentials, :client_name, :header_name
      end
    end
  end

  describe '.perform_request' do
    before do
      test_class.credentials = { public_key: OpenSSL::PKey::RSA.new(2048).public_key.to_s }
      test_class.client_name = 'test_client'
      allow(Time).to receive_message_chain(:now, :utc, :to_i).and_return(12345)
    end

    context 'with custom header_name' do
      before do
        test_class.header_name = 'Custom-Auth'
        test_class.base_uri 'https://example.com'
        test_class.headers({}) # Initialize headers
      end

      it 'sets custom header with secure token' do
        stub = stub_request(:get, 'https://example.com/test')
          .with { |req| req.headers['Custom-Auth'] }
        test_class.get('/test')

        expect(stub).to have_been_requested
      end
    end

    context 'without custom header_name' do
      before do
        test_class.header_name = nil
        test_class.base_uri 'https://example.com'
        test_class.headers({}) # Initialize headers
      end

      it 'uses default Secure-Token header' do
        stub = stub_request(:get, 'https://example.com/test')
          .with { |req| req.headers['Secure-Token'] }
        test_class.get('/test')

        expect(stub).to have_been_requested
      end
    end
  end

  describe 'DEFAULT_HEADER_NAME' do
    it 'is set to Secure-Token' do
      expect(described_class::DEFAULT_HEADER_NAME).to eq('Secure-Token')
    end
  end
end
