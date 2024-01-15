module PayrentClientSocket
  module HTTP
    # This allows us to set dynamic headers every time we make a request
    module HTTPartyOverrides
      DEFAULT_HEADER_NAME = 'Secure-Token'.freeze

      def self.included(base)
        base.singleton_class.prepend(ClassMethods)
        base.private_class_method *ClassMethods.instance_methods(false)
      end

      module ClassMethods
        def perform_request(http_method, path, options, &block)
          headers[header_name || DEFAULT_HEADER_NAME] = secure_token
          super(http_method, path, options, &block)
        end
      end
    end
  end
end
