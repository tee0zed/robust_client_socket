module PayrentClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :keychain, :service_name

      def self.init(keychain:, service_name:)
        self.keychain = keychain
        self.service_name = service_name

        base_uri keychain[:base_uri]
        headers payrent_headers
      end
    end
  end
end
