module PayrentClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :credentials, :service_name

      def self.init(credentials:, service_name:)
        self.credentials = credentials
        self.service_name = service_name

        base_uri credentials[:base_uri]
        headers payrent_headers
      end
    end
  end
end
