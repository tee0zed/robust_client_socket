module RobustClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :credentials, :client_name, :header_name

      def self.init(credentials:, client_name:, header_name: nil)
        base_uri_value = credentials[:base_uri]
        raise SecurityError, "HTTPS required in production" if HTTP.production? && !base_uri_value.start_with?('https://')

        self.credentials = credentials
        self.client_name = client_name
        self.header_name = header_name

        base_uri base_uri_value
        headers robust_headers

        # Force SSL certificate verification
        default_options.merge!(
          verify: true,
          verify_mode: OpenSSL::SSL::VERIFY_PEER
        )
      end
    end

    def self.production?
      if defined? Rails
        Rails.production?
      else
        ENV.fetch("RACK_ENV") { 'development' } == 'production'
      end
    end
  end
end
