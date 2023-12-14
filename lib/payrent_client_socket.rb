# frozen_string_literal: true

require_relative 'version'
require_relative 'payrent_client_socket/configuration'

module PayrentClientSocket
  extend PayrentClientSocket::Configuration
  extend self

  def load!
    raise "You must configure PayrentClientSocket first!" unless configured?

    require 'openssl'
    require 'httparty'
    require 'base64'
    require 'oj'

    require_relative 'payrent_client_socket/http/httparty_overrides'
    require_relative 'payrent_client_socket/http/helpers'
    require_relative 'payrent_client_socket/http/client'

    configuration.services.each do |key, value|
      client = Class.new(PayrentClientSocket::HTTP::Client)
      client.init(credentials: value, client_name: configuration.client_name)
      const_set(key.to_s.split('_').map(&:capitalize).join, client)
    end
  end
end
