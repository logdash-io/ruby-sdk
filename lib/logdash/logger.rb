# frozen_string_literal: true

require 'json'
require 'time'

module Logdash
  module Types
    module LogLevel
      ERROR = 'error'
      WARN = 'warning'
      INFO = 'info'
      HTTP = 'http'
      VERBOSE = 'verbose'
      DEBUG = 'debug'
      SILLY = 'silly'
    end
  end

  class Logger
    LOG_LEVEL_COLORS = {
      Logdash::Types::LogLevel::ERROR => [231, 0, 11],
      Logdash::Types::LogLevel::WARN => [254, 154, 0],
      Logdash::Types::LogLevel::INFO => [21, 93, 252],
      Logdash::Types::LogLevel::HTTP => [0, 166, 166],
      Logdash::Types::LogLevel::VERBOSE => [0, 166, 0],
      Logdash::Types::LogLevel::DEBUG => [0, 166, 62],
      Logdash::Types::LogLevel::SILLY => [80, 80, 80]
    }.freeze

    def initialize(log_sync: nil, prefix_proc: nil, on_log_proc: nil)
      @log_sync = log_sync
      @prefix_proc = prefix_proc || default_prefix_proc
      @on_log_proc = on_log_proc
    end

    Logdash::Types::LogLevel.constants.each do |level_const_sym|
      level_value = Logdash::Types::LogLevel.const_get(level_const_sym)
      define_method(level_value) do |*data|
        _log(level_value, format_data(data))
      end
    end

    alias log info
    alias warn warning

    private

    def format_data(data)
      data.map do |item|
        item.is_a?(String) ? item : item.to_json
      rescue JSON::GeneratorError
        item.to_s
      end.join(' ')
    end

    def colorize(text, level)
      rgb = LOG_LEVEL_COLORS[level]
      return text unless rgb

      "\e[38;2;#{rgb[0]};#{rgb[1]};#{rgb[2]}m#{text}\e[0m"
    end

    def iso8601_timestamp
      Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
    end

    def default_prefix_proc
      lambda do |level, timestamp|
        timestamp = colorize("[#{timestamp}]", Logdash::Types::LogLevel::SILLY)
        level_tag = colorize("[#{level.to_s.upcase}]", level)
        "#{timestamp} #{level_tag} "
      end
    end

    def _log(level, message)
      timestamp = iso8601_timestamp
      prefix = @prefix_proc.call(level, timestamp)

      puts "#{prefix}#{message}"

      @on_log_proc&.call(level, message)
      @log_sync&.send(message, level, timestamp)
    end
  end
end
