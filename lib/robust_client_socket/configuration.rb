module RobustClientSocket
  module Configuration
    MIN_KEY_SIZE = 2048

    attr_reader :configuration, :configured

    def configure
      @configuration ||= ConfigStore.new
      yield(configuration)
      validate_keys_security!

      @configured = true
    end

    def correct_configuration?
      return false unless configuration.services.is_a?(Hash)
      return false if configuration.services.empty?
      return false if configuration.client_name.nil?

      configuration.services.all? do |_, creds|
        creds.key?(:base_uri) && creds.key?(:public_key)
      end
    end

    def configured?
      !!@configured && correct_configuration?
    end

    private

    def validate_keys_security!
      configuration.services.each do |service_name, creds|
        next unless creds[:public_key]

        key = OpenSSL::PKey::RSA.new(creds[:public_key])
        key_bits = key.n.num_bits

        if key_bits < MIN_KEY_SIZE
          raise SecurityError,
            "RSA key size for #{service_name} (#{key_bits} bits) below minimum (#{MIN_KEY_SIZE} bits)"
        end

        raise SecurityError, "Invalid public key for #{service_name}" unless key.public?
      rescue OpenSSL::PKey::RSAError => e
        raise SecurityError, "Invalid public key for #{service_name}: #{e.message}"
      end
    end
  end

  class ConfigStore
    attr_reader :services
    attr_accessor :client_name, :header_name

    def initialize
      @services = {}
      @client_name = nil
    end

    def method_missing(name, *args) # rubocop:disable Style/MissingRespondToMissing
      if name.end_with?('=')
        @services[name.to_s.delete_suffix('=').to_sym] = args.first.is_a?(Hash) && args.pop
      else
        super
      end
    end
  end
end
