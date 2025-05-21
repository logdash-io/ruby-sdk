# frozen_string_literal: true

require 'spec_helper'
require 'logdash/client'

RSpec.describe Logdash::Client do
  let(:api_key) { 'test_api_key' }
  let(:host) { 'https://test.logdash.io' }

  describe '#initialize' do
    context 'with an API key' do
      subject(:client) { described_class.new(api_key: api_key, host: host, verbose: true) }

      it 'initializes a Logger' do
        expect(client.logger).to be_a(Logdash::Logger)
      end

      it 'initializes HttpLogSync' do
        expect(client.logger.instance_variable_get(:@log_sync)).to be_a(Logdash::HttpLogSync)
      end

      it 'initializes Metrics' do
        expect(client.metrics).to be_a(Logdash::Metrics)
      end

      it 'passes verbose true to HttpLogSync' do
        http_log_sync = class_spy(Logdash::HttpLogSync)
        stub_const('Logdash::HttpLogSync', http_log_sync)
        client
        expect(http_log_sync).to have_received(:new).with(api_key: api_key, host: host, verbose: true)
      end

      it 'passes verbose true to Metrics' do
        metrics = class_spy(Logdash::Metrics)
        stub_const('Logdash::Metrics', metrics)
        client
        expect(metrics).to have_received(:new).with(api_key: api_key, host: host, verbose: true)
      end
    end

    context 'without an API key' do
      subject(:client) { described_class.new(verbose: true) }

      it 'initializes a Logger' do
        expect(client.logger).to be_a(Logdash::Logger)
      end

      it 'initializes NoopLogSync' do
        expect(client.logger.instance_variable_get(:@log_sync)).to be_a(Logdash::NoopLogSync)
      end

      it 'initializes NoopMetrics' do
        expect(client.metrics).to be_a(Logdash::NoopMetrics)
      end

      it 'outputs messages about local logger and no metrics when verbose' do
        expect { client }.to output(/API key not provided/).to_stdout
      end
    end

    context 'with verbose false (default)' do
      subject(:client) { described_class.new }

      it 'does not output messages' do
        expect { client }.not_to output.to_stdout
      end
    end
  end

  describe '.create' do
    context 'with an API key' do
      subject(:services) { described_class.create(api_key: api_key, host: host) }

      it 'contains a Logger' do
        expect(services[:logger]).to be_a(Logdash::Logger)
      end

      it 'contains a Metrics' do
        expect(services[:metrics]).to be_a(Logdash::Metrics)
      end

      it 'configures Logger with HttpLogSync' do
        expect(services[:logger].instance_variable_get(:@log_sync)).to be_a(Logdash::HttpLogSync)
      end
    end

    context 'without an API key' do
      subject(:services) { described_class.create }

      it 'initializes NoopMetrics' do
        expect(services[:metrics]).to be_a(Logdash::NoopMetrics)
      end

      it 'initializes Logger with NoopLogSync' do
        expect(services[:logger]).to be_a(Logdash::Logger)
      end

      it 'configures Logger with NoopLogSync' do
        expect(services[:logger].instance_variable_get(:@log_sync)).to be_a(Logdash::NoopLogSync)
      end
    end
  end
end
