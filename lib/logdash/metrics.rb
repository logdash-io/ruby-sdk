# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Logdash
  module BaseMetrics
    def set(key, value)
      raise NotImplementedError, "#{self.class} has not implemented method 'set'"
    end

    def mutate(key, value)
      raise NotImplementedError, "#{self.class} has not implemented method 'mutate'"
    end
  end

  module MetricOperation
    SET = 'set'
    CHANGE = 'change'
  end

  class Metrics
    include BaseMetrics

    def initialize(api_key:, host:, verbose:)
      @api_key = api_key
      @host = host
      @verbose = verbose
    end

    def set(name, value)
      puts "[LogDash] Setting metric #{name} to #{value}" if @verbose
      send_metric_async(name, value, MetricOperation::SET)
    end

    def mutate(name, value)
      puts "[LogDash] Mutating metric #{name} by #{value}" if @verbose
      send_metric_async(name, value, MetricOperation::CHANGE)
    end

    private

    def send_metric_async(name, value, operation)
      return unless @api_key

      Thread.new do
        uri = URI.parse("#{@host}/metrics")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = 5
        http.read_timeout = 5

        request = Net::HTTP::Put.new(uri.request_uri)
        request['Content-Type'] = 'application/json'
        request['project-api-key'] = @api_key
        request.body = {
          name: name,
          value: value,
          operation: operation
        }.to_json

        response = http.request(request)
        puts "[LogDash BG] Sent metric (#{name}, op: #{operation}), status: #{response.code}" if @verbose
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        puts "[LogDash BG] Timeout sending metric (#{name}): #{e.message}" if @verbose
      rescue StandardError => e
        puts "[LogDash BG] Error sending metric (#{name}): #{e.message}" if @verbose
      end
    end
  end

  class NoopMetrics
    include BaseMetrics

    def set(key, value)
      # No operation
    end

    def mutate(key, value)
      # No operation
    end
  end
end
