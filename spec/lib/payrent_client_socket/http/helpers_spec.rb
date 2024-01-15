require 'spec_helper'
require 'openssl'
require 'base64'
require './lib/payrent_client_socket/http/helpers.rb'

RSpec.describe PayrentClientSocket::HTTP::Helpers do
  let(:dummy_class) do
    Class.new do
      include PayrentClientSocket::HTTP::Helpers

      singleton_class.attr_accessor :credentials, :client_name

      def self.service_uri
      end

      def self.public_key
      end
    end
  end

  describe 'PrivateClassMethods' do
    describe '.payrent_headers' do
      it 'returns the correct headers' do
        expected_headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }

        expect(dummy_class.send(:payrent_headers)).to eq(expected_headers)
      end
    end

    describe '.secure_token' do
      it 'returns the encrypted token' do
        allow(::OpenSSL::PKey::RSA).to receive_message_chain(:new, :public_encrypt).and_return('encrypted_token')
        allow(::Base64).to receive(:strict_encode64).with('encrypted_token').and_return('base64_encrypted_token')
        allow(dummy_class).to receive(:public_key).and_return('public_key')
        allow(dummy_class).to receive(:app_token).and_return('app_token')

        expect(dummy_class.send(:secure_token)).to eq('base64_encrypted_token')
      end
    end

    describe '.app_token' do
      it 'fetches the app token from configuration' do
        allow(dummy_class).to receive(:client_name).and_return('client_name')

        expect(dummy_class.send(:app_token)).to match(/client_name_+\d/)
      end
    end
  end
end
