require 'spec_helper'
require 'openssl'
require 'base64'
require 'httparty'
require './lib/payrent_client_socket/configuration.rb'
require './lib/payrent_client_socket/http/helpers.rb'
require './lib/payrent_client_socket/http/httparty_overrides.rb'

module PayrentClientSocket
  extend PayrentClientSocket::Configuration
end

RSpec.describe PayrentClientSocket::HTTP::HTTPartyOverrides do
  let(:dummy_class) do
    Class.new do
      include HTTParty
      include PayrentClientSocket::HTTP::Helpers
      include PayrentClientSocket::HTTP::HTTPartyOverrides

      def self.credentials
        {
          public_key: 'public_key',
          base_uri: 'https://example.com'
        }
      end

      def self.service_name
        'service_name'
      end

      base_uri 'https://example.com'
      headers payrent_headers
    end
  end

  describe '.post' do
    before do
      allow_any_instance_of(HTTParty::Request).to receive(:perform).and_return('response')
    end

    it 'calls the original post method with updated headers every time' do
      allow(dummy_class).to receive(:secure_token).and_return('secure_token')
      dummy_class.post('/')
      expect(dummy_class.send(:headers)).to include('secure-token' => 'secure_token')

      allow(dummy_class).to receive(:secure_token).and_return('other_secure_token')
      dummy_class.post('/')
      expect(dummy_class.send(:headers)).to include('secure-token' => 'other_secure_token')
    end
  end
end
