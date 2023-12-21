module PayrentClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :credentials, :client_name, :header_name

      def self.init(credentials:, client_name:, header_name: nil)
        self.credentials = credentials
        self.client_name = client_name
        self.header_name = header_name

        base_uri credentials[:base_uri]
        headers payrent_headers
      end
    end
  end
end
