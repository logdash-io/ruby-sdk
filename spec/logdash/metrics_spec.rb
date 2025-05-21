# frozen_string_literal: true

require 'spec_helper'
require 'logdash/metrics'

RSpec.describe Logdash::Metrics do
  subject(:metrics) { described_class.new(api_key: api_key, host: host, verbose: verbose) }

  let(:api_key) { 'test_api_key' }
  let(:host) { 'https://test.logdash.io' }
  let(:verbose) { false }

  before do
    stub_request(:put, "#{host}/metrics")
  end

  describe '#set' do
    it 'sends a set metric request' do
      metrics.set('metric_name', 10)
      # Allow time for the thread to execute
      sleep 0.1
      expect(WebMock).to have_requested(:put, "#{host}/metrics")
        .with(body: { name: 'metric_name', value: 10, operation: Logdash::MetricOperation::SET }.to_json,
              headers: { 'Content-Type' => 'application/json', 'project-api-key' => api_key }).once
    end
  end

  describe '#mutate' do
    it 'sends a mutate metric request' do
      metrics.mutate('metric_name', 5)
      sleep 0.1
      expect(WebMock).to have_requested(:put, "#{host}/metrics")
        .with(body: { name: 'metric_name', value: 5, operation: Logdash::MetricOperation::CHANGE }.to_json,
              headers: { 'Content-Type' => 'application/json', 'project-api-key' => api_key }).once
    end
  end

  context 'when api_key is nil' do
    let(:api_key) { nil }

    describe '#set' do
      it 'does not send a request' do
        metrics.set('metric_name', 10)
        sleep 0.1
        expect(WebMock).not_to have_requested(:put, "#{host}/metrics")
      end
    end

    describe '#mutate' do
      it 'does not send a request' do
        metrics.mutate('metric_name', 5)
        sleep 0.1
        expect(WebMock).not_to have_requested(:put, "#{host}/metrics")
      end
    end
  end

  describe Logdash::NoopMetrics do
    subject(:noop_metrics) { described_class.new }

    describe '#set' do
      it 'does nothing' do
        expect { noop_metrics.set('key', 'value') }.not_to raise_error
      end

      it 'does not output anything' do
        expect { noop_metrics.set('key', 'value') }.not_to output.to_stdout
      end
    end

    describe '#mutate' do
      it 'does nothing' do
        expect { noop_metrics.mutate('key', 1) }.not_to raise_error
      end

      it 'does not output anything' do
        expect { noop_metrics.mutate('key', 1) }.not_to output.to_stdout
      end
    end
  end
end
