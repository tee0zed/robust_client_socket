require 'spec_helper'
require './lib/payrent_client_socket.rb'

RSpec.describe PayrentClientSocket do
  describe '.load' do
    before do
      PayrentClientSocket.configure do |config|
        config.keychain = {
          service_one: {
            base_uri: 'https://example1.com',
            public_key: 'public_key'
          },
          service_two: {
            base_uri: 'https://example2.com',
            public_key: 'public_key'
          }
        }
      end
    end

    it 'loads services as separate classes' do
      PayrentClientSocket.load!
      expect(PayrentClientSocket::ServiceOne).to be_a(Class)
      expect(PayrentClientSocket::ServiceTwo).to be_a(Class)
    end

    it 'loads services with correct base_uri' do
      PayrentClientSocket.load!
      expect(PayrentClientSocket::ServiceOne.base_uri).to eq('https://example1.com')
      expect(PayrentClientSocket::ServiceTwo.base_uri).to eq('https://example2.com')
    end
  end
end
