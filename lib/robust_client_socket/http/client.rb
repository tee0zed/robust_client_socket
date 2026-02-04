module RobustClientSocket
  module HTTP
    class Client
      include Helpers
      include HTTParty
      include HTTPartyOverrides

      singleton_class.attr_accessor :credentials, :client_name, :header_name

      InsecureConnectionError = Class.new(StandardError)
      InvalidCredentialsError = Class.new(StandardError)

      class << self
        def init(credentials:, client_name:, header_name: nil)
          validate_credentials!(credentials)
          enforce_https!(credentials[:base_uri])

          self.credentials = credentials
          self.client_name = client_name
          self.header_name = header_name

          base_uri credentials[:base_uri]
          headers robust_headers
          configure_ssl(credentials)
          configure_timeouts(credentials)
        end

        private

        def validate_credentials!(credentials)
          required_keys = [:base_uri, :public_key]
          missing = required_keys - credentials.keys

          raise InvalidCredentialsError, "Missing keys: #{missing.join(', ')}" if missing.any?
          raise InvalidCredentialsError, "public_key cannot be empty" if credentials[:public_key].to_s.strip.empty?
        end

        def enforce_https!(uri)
          return if uri.start_with?('https://')
          return unless production?

          raise InsecureConnectionError,
            "HTTPS required in production. Use https:// instead of #{uri}"
        end

        def configure_ssl(credentials)
          default_options.update(
            verify: credentials.fetch(:ssl_verify, true),
            ssl_version: :TLSv1_2,
            ciphers: [
              'ECDHE-RSA-AES128-GCM-SHA256',
              'ECDHE-RSA-AES256-GCM-SHA384',
              'ECDHE-ECDSA-AES128-GCM-SHA256',
              'ECDHE-ECDSA-AES256-GCM-SHA384'
            ].join(':'),
            verify_mode: OpenSSL::SSL::VERIFY_PEER
          )
        end

        def configure_timeouts(credentials)
          default_options.update(
            timeout: credentials.fetch(:timeout, 10),
            open_timeout: credentials.fetch(:open_timeout, 5)
          )
        end

        def production?
          if defined? Rails
            Rails.env.production?
          else
            ENV.fetch("RACK_ENV", "development") == 'production'
          end
        end
      end
    end
  end
end
