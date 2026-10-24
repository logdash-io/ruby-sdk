# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'
require_relative 'logger'

module Logdash
  class Events
    NAME = /\A[a-z][a-z0-9_]{0,63}\z/.freeze
    WEBSITE_EVENTS = %w[pageview pageleave browser_error].freeze

    # Ruby kills the threads still sending events when the main thread exits, so it waits for them first
    SENDING = ThreadGroup.new
    at_exit { SENDING.list.each(&:join) }

    def initialize(api_key:, host:, verbose:, app: nil)
      @api_key = api_key
      @host = host
      @verbose = verbose
      @app = app
      @console = Logger.new
    end

    # Ruby < 3 passes a braced props hash as keywords, so keywords other than user_id are props too
    def track(name, props = {}, user_id: nil, **more_props)
      name = name.to_s
      user_id = user_id.to_s
      validate(name, user_id)
      props = props.to_h.merge(more_props)
      return @console.info("Event #{name} #{props.to_json}") if @api_key.to_s.empty?

      body = event_body(name, props, user_id)
      SENDING.add(Thread.new { send_event(name, body) })
    rescue StandardError => e
      @console.warn("Dropping event #{name.inspect}: #{e.message}")
    end

    # Waits for the events still being sent, for example before a serverless function returns
    def flush
      SENDING.list.each(&:join)
    end

    private

    def validate(name, user_id)
      if !NAME.match?(name) || WEBSITE_EVENTS.include?(name)
        raise ArgumentError, 'its name must match [a-z][a-z0-9_]{0,63} and not be pageview, pageleave or browser_error'
      end
      raise ArgumentError, 'user_id must be an internal ID, never an email address' if user_id.include?('@')
    end

    def event_body(name, props, user_id)
      # The server stores an event once per id, so a retry must send this same body
      body = { id: SecureRandom.uuid, name: name }
      body[:props] = props unless props.empty?
      body[:userId] = user_id unless user_id.empty?
      body[:app] = @app if @app && !@app.empty?
      body.to_json
    end

    def send_event(name, body)
      uri = URI.parse("#{@host}/events")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 5
      http.read_timeout = 5
      response = http.post(uri.request_uri, body, 'Content-Type' => 'application/json', 'project-api-key' => @api_key)
      puts "[LogDash BG] Sent event (#{name}), status: #{response.code}" if @verbose
    rescue StandardError => e
      puts "[LogDash BG] Error sending event (#{name}): #{e.message}" if @verbose
    end
  end
end
