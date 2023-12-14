module PayrentClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :credentials

      def self.init(credentials:, client_name:)
        self.credentials = credentials
        self.client_name = client_name

        base_uri credentials[:base_uri]
        headers payrent_headers
      end
    end
  end
end
