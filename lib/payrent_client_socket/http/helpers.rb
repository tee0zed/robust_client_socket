module PayrentClientSocket
  module HTTP
    module Helpers
      def self.included(base)
        base.extend(PrivateClassMethods)
        base.private_class_method *PrivateClassMethods.instance_methods(false)

        base.extend(PublicClassMethods)
      end
    end

    module PublicClassMethods
      def encrypt_message(message)
        encrypted_data(message_with_timestamp(message))
      end

      def message_with_timestamp(message)
        "#{message}_#{time_now_in_utc}"
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
        encrypted_data(app_token)
      end

      def encrypted_data(data)
        ::Base64.strict_encode64(::OpenSSL::PKey::RSA.new(public_key).public_encrypt(data))
      end

      def public_key
        credentials[:public_key]
      end

      def app_token
        "#{client_name}_#{time_now_in_utc}"
      end

      def time_now_in_utc
        Time.now.utc.to_i
      end
    end
  end
end
