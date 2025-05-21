# frozen_string_literal: true

require_relative 'logger'
require_relative 'metrics'
require_relative 'http_log_sync'

module Logdash
  class Client
    attr_reader :logger, :metrics

    def initialize(api_key: nil, host: 'https://api.logdash.io', verbose: false)
      @api_key = api_key
      @host = host
      @verbose = verbose

      log_sync_instance = create_log_sync(api_key, host, verbose)
      @logger = Logger.new(log_sync: log_sync_instance)

      @metrics = create_metrics(api_key, host, verbose)
    end

    def self.create(api_key: nil, host: 'https://api.logdash.io', verbose: false)
      client = new(api_key: api_key, host: host, verbose: verbose)
      { logger: client.logger, metrics: client.metrics }
    end

    private

    def create_log_sync(api_key, host, verbose)
      if api_key && !api_key.empty?
        HttpLogSync.new(api_key: api_key, host: host, verbose: verbose)
      else
        puts '[LogDash] API key not provided. Using local logger only.' if verbose
        NoopLogSync.new
      end
    end

    def create_metrics(api_key, host, verbose)
      if api_key && !api_key.empty?
        Metrics.new(api_key: api_key, host: host, verbose: verbose)
      else
        puts '[LogDash] API key not provided. Metrics will not be registered.' if verbose
        NoopMetrics.new
      end
    end
  end
end
