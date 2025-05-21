# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Logdash
  class HttpLogSync
    def initialize(api_key:, host:, verbose:)
      @api_key = api_key
      @host = host
      @verbose = verbose
      @sequence_number = 0
      @sequence_mutex = Mutex.new
    end

    def send(message, level, created_at)
      return unless @api_key

      payload_sequence_number = next_sequence_number

      Thread.new do
        send_log_message(message, level, created_at, payload_sequence_number)
      end
    end

    private

    def next_sequence_number
      @sequence_mutex.synchronize do
        current_sequence = @sequence_number
        @sequence_number += 1
        current_sequence
      end
    end

    def send_log_message(message, level, created_at, sequence_number)
      uri = URI.parse("#{@host}/logs")
      request = build_request(uri, message, level, created_at, sequence_number)

      begin
        response = http_client(uri).request(request)
        puts "[LogDash BG] Sent log (seq: #{sequence_number}), status: #{response.code}" if @verbose
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        puts "[LogDash BG] Timeout sending log (seq: #{sequence_number}): #{e.message}" if @verbose
      rescue StandardError => e
        puts "[LogDash BG] Error sending log (seq: #{sequence_number}): #{e.message}" if @verbose
      end
    end

    def build_request(uri, message, level, created_at, sequence_number)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['project-api-key'] = @api_key
      request.body = {
        message: message,
        level: level,
        createdAt: created_at,
        sequenceNumber: sequence_number
      }.to_json
      request
    end

    def http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 5
      http.read_timeout = 5
      http
    end
  end

  class NoopLogSync
    def send(message, level, created_at); end
  end
end
