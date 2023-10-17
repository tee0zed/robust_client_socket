module PayrentClientSocket
  module Configuration
    attr_reader :configuration, :configured

    def configure
      @configuration ||= ConfigStore.new
      yield(configuration)

      @configured = true
    end

    def correct_configuration?
      return false unless configuration.keychain.is_a?(Hash)

      configuration.keychain.all? do |service_name, keychain|
        keychain.key?(:base_uri) && keychain.key?(:public_key)
      end
    end

    def configured?
      !!@configured && correct_configuration?
    end
  end

  class ConfigStore
    attr_accessor :keychain
  end
end
