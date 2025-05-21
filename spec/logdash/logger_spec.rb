# frozen_string_literal: true

require 'spec_helper'
require 'logdash/logger'

RSpec.describe Logdash::Logger do
  let(:logger) { described_class.new }

  describe '#initialize' do
    it 'creates a new logger instance' do
      expect(logger).to be_a(described_class)
    end
  end

  Logdash::Types::LogLevel.constants.each do |level_const_sym|
    level_value = Logdash::Types::LogLevel.const_get(level_const_sym)
    describe "##{level_value}" do
      it "logs a message with level #{level_value}" do
        expect { logger.public_send(level_value, 'test message') }.to output.to_stdout
      end

      it 'calls on_log_proc if provided' do
        on_log_proc_called = false
        on_log_proc = ->(_level, _message) { on_log_proc_called = true }
        logger_with_proc = described_class.new(on_log_proc: on_log_proc)
        logger_with_proc.public_send(level_value, 'test message')
        expect(on_log_proc_called).to be true
      end
    end
  end

  describe '#log' do
    it 'is an alias for info' do
      expect(logger.method(:log)).to eq(logger.method(:info))
    end
  end

  describe 'private methods' do
    describe '#format_data' do
      it 'formats string data' do
        expect(logger.send(:format_data, ['test message'])).to eq('test message')
      end

      it 'formats non-string data to json' do
        expect(logger.send(:format_data, [{ key: 'value' }])).to eq('{"key":"value"}')
      end

      it 'formats multiple data items' do
        expect(logger.send(:format_data, ['test', { key: 'value' }])).to eq('test {"key":"value"}')
      end

      it 'handles JSON generation errors gracefully' do
        data_with_proc = [proc {}]
        expect(logger.send(:format_data, data_with_proc)).to match(/#<Proc:0x[0-9a-f]+ .+>/)
      end
    end

    describe '#colorize' do
      it 'colorizes text based on level' do
        Logdash::Types::LogLevel.constants.each do |level_const_sym|
          level_value = Logdash::Types::LogLevel.const_get(level_const_sym)
          expect(colorized_text(level_value)).to eq(expected_colorized_text(level_value))
        end
      end

      def colorized_text(level_value)
        logger.send(:colorize, 'text', level_value)
      end

      def expected_colorized_text(level_value)
        color = Logdash::Logger::LOG_LEVEL_COLORS[level_value]
        "\e[38;2;#{color[0]};#{color[1]};#{color[2]}mtext\e[0m"
      end

      it 'returns text if color not found for level' do
        expect(logger.send(:colorize, 'text', 'unknown_level')).to eq('text')
      end
    end

    describe '#default_prefix_proc' do
      it 'returns a proc' do
        expect(logger.send(:default_prefix_proc)).to be_a(Proc)
      end

      it 'proc returns a formatted string with timestamp and level' do
        Timecop.freeze(Time.utc(2024, 1, 1, 12, 0, 0)) do
          prefix = logger.send(:default_prefix_proc).call(Logdash::Types::LogLevel::INFO)
          expect(prefix).to eq(expected_formatted_prefix)
        end
      end

      def expected_formatted_prefix
        "#{expected_timestamp} #{expected_level_tag} "
      end

      def expected_timestamp
        "\e[38;2;80;80;80m[2024-01-01T12:00:00Z]\e[0m"
      end

      def expected_level_tag
        "\e[38;2;21;93;252m[INFO]\e[0m"
      end
    end

    describe '#_log' do
      it 'outputs the formatted log message' do
        Timecop.freeze(Time.utc(2024, 1, 1, 12, 0, 0)) do
          expect { logger.send(:_log, Logdash::Types::LogLevel::INFO, 'test message') }
            .to output(expected_log_output).to_stdout
        end
      end

      def expected_log_output
        "#{expected_timestamp} #{expected_level_tag} test message\n"
      end

      def expected_timestamp
        "\e[38;2;80;80;80m[2024-01-01T12:00:00Z]\e[0m"
      end

      def expected_level_tag
        "\e[38;2;21;93;252m[INFO]\e[0m"
      end

      it 'calls on_log_proc' do
        on_log_proc_called_with = nil
        on_log_proc = ->(level, message) { on_log_proc_called_with = [level, message] }
        logger_with_proc = described_class.new(on_log_proc: on_log_proc)
        logger_with_proc.send(:_log, Logdash::Types::LogLevel::DEBUG, 'debug test')
        expect(on_log_proc_called_with).to eq([Logdash::Types::LogLevel::DEBUG, 'debug test'])
      end
    end
  end
end
