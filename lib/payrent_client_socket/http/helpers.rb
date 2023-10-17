module PayrentClientSocket
  module HTTP
    module Helpers
      def self.included(base)
        base.extend(PrivateClassMethods)
        base.private_class_method *PrivateClassMethods.instance_methods(false)
      end
    end

    module PrivateClassMethods
      def payrent_headers
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      end

      def secure_token
        ::Base64.strict_encode64(::OpenSSL::PKey::RSA.new(public_key).public_encrypt(app_token))
      end

      def public_key
        keychain[:public_key]
      end

      def app_token
        "#{service_name}_#{time_now_in_utc}"
      end

      def time_now_in_utc
        Time.now.utc.to_i
      end
    end
  end
end
