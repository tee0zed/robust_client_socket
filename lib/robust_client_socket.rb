# frozen_string_literal: true

require_relative 'version'
require_relative 'robust_client_socket/configuration'

module RobustClientSocket
  extend RobustClientSocket::Configuration

  module_function

  def load! # rubocop:disable Metrics/AbcSize
    raise 'You must configure RobustClientSocket first!' unless configured?

    require 'openssl'
    require 'httparty'
    require 'base64'
    require 'oj'

    require_relative 'robust_client_socket/http/httparty_overrides'
    require_relative 'robust_client_socket/http/helpers'
    require_relative 'robust_client_socket/http/client'

    configuration.services.each do |key, value|
      client = Class.new(RobustClientSocket::HTTP::Client)
      client.init(credentials: value, client_name: configuration.client_name, header_name: configuration.header_name)
      const_set(key.to_s.split('_').map(&:capitalize).join, client)
    end
  end
end
