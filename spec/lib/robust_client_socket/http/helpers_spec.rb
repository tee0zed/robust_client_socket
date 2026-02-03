require 'spec_helper'
require 'openssl'
require 'base64'
require './lib/robust_client_socket/http/helpers.rb'

RSpec.describe RobustClientSocket::HTTP::Helpers do
  let(:dummy_class) do
    Class.new do
      include RobustClientSocket::HTTP::Helpers

      singleton_class.attr_accessor :credentials, :client_name

      def self.service_uri
      end

      def self.public_key
      end
    end
  end

  describe 'PublicClassMethods' do
    describe '.encrypt_message' do
      it 'returns the encrypted message' do
        allow(::OpenSSL::PKey::RSA).to receive_message_chain(:new, :public_encrypt).and_return('encrypted_message')
        allow(::Base64).to receive(:strict_encode64).with('encrypted_message').and_return('base64_encrypted_message')
        allow(dummy_class).to receive(:public_key).and_return('public_key')
        allow(dummy_class).to receive(:message_with_timestamp).and_return('message_with_timestamp')

        expect(dummy_class.encrypt_message('message')).to eq('base64_encrypted_message')
      end
    end
  end

  describe 'PrivateClassMethods' do
    describe '.robust_headers' do
      it 'returns the correct headers' do
        expected_headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }

        expect(dummy_class.send(:robust_headers)).to eq(expected_headers)
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

    describe '.public_key' do
      it 'extracts public_key from credentials' do
        dummy_class.credentials = { public_key: 'test_key' }
        expect(dummy_class.send(:credentials)[:public_key]).to eq('test_key')
      end
    end

    describe '.time_now_in_utc' do
      it 'returns current UTC timestamp' do
        allow(Time).to receive_message_chain(:now, :utc, :to_i).and_return(1234567890)
        expect(dummy_class.send(:time_now_in_utc)).to eq(1234567890)
      end
    end

    describe '.encrypted_data' do
      it 'encrypts and base64 encodes data' do
        rsa_key = OpenSSL::PKey::RSA.new(2048)
        allow(dummy_class).to receive(:public_key).and_return(rsa_key.public_key.to_s)

        result = dummy_class.send(:encrypted_data, 'test_data')
        expect(result).to be_a(String)
        expect { Base64.strict_decode64(result) }.not_to raise_error
      end
    end
  end
end
