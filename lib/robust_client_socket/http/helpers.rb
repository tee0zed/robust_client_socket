module RobustClientSocket
  module HTTP
    module Helpers
      def self.included(base)
        base.extend(PrivateClassMethods)
        base.private_class_method(*PrivateClassMethods.instance_methods(false))
      end
    end

    module PrivateClassMethods
      MIN_KEY_SIZE = 2048

      def robust_headers
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'User-Agent' => "RobustClientSocket/#{RobustClientSocket::VERSION}"
        }
      end

      def secure_token
        encrypted_data(app_token)
      end

      def encrypted_data(data)
        validate_key_security!

        encrypted = rsa_key.public_encrypt(
          data,
          OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
        )

        ::Base64.strict_encode64(encrypted)
      rescue OpenSSL::PKey::RSAError => e
        raise SecurityError, "Encryption failed: #{e.message}"
      end

      def rsa_key
        @rsa_key ||= begin
          key = OpenSSL::PKey::RSA.new(public_key)
          raise SecurityError, "Invalid public key" unless key.public?
          key
        end
      end

      def validate_key_security!
        key_bits = rsa_key.n.num_bits

        if key_bits < MIN_KEY_SIZE
          raise SecurityError,
            "RSA key size (#{key_bits} bits) below minimum (#{MIN_KEY_SIZE} bits)"
        end
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
