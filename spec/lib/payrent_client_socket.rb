require 'spec_helper'
require './lib/robust_client_socket.rb'

RSpec.describe RobustClientSocket do
  describe '.load' do
    before do
      RobustClientSocket.configure do |config|
        config.service_one = {
          base_uri: 'https://example1.com',
          public_key: 'public_key'
        }
        config.service_two = {
          base_uri: 'https://example2.com',
          public_key: 'public_key'
        }
      end
    end

    it 'loads services as separate classes' do
      RobustClientSocket.load!
      expect(RobustClientSocket::ServiceOne).to be_a(Class)
      expect(RobustClientSocket::ServiceTwo).to be_a(Class)
    end

    it 'loads services with correct base_uri' do
      RobustClientSocket.load!
      expect(RobustClientSocket::ServiceOne.base_uri).to eq('https://example1.com')
      expect(RobustClientSocket::ServiceTwo.base_uri).to eq('https://example2.com')
    end
  end
end
