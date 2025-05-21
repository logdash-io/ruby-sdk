# frozen_string_literal: true

require_relative 'logdash/client'
require_relative 'logdash/version'
require_relative 'logdash/logger'

module Logdash
  def self.create(api_key: nil, host: 'https://api.logdash.io', verbose: false)
    Client.create(api_key: api_key, host: host, verbose: verbose)
  end

  def self.new_client(api_key: nil, host: 'https://api.logdash.io', verbose: false)
    Client.new(api_key: api_key, host: host, verbose: verbose)
  end
end
