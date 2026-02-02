module RobustClientSocket
  module Configuration
    attr_reader :configuration, :configured

    def configure
      @configuration ||= ConfigStore.new
      yield(configuration)

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
