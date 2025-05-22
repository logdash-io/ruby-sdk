# frozen_string_literal: true

require 'spec_helper'
require 'logdash/http_log_sync'
require 'webmock/rspec'

RSpec.describe Logdash::HttpLogSync do
  let(:api_key) { 'test_api_key' }
  let(:host) { 'https://api.logdash.com' }
  let(:verbose) { false }
  let(:log_sync) { described_class.new(api_key: api_key, host: host, verbose: verbose) }

  describe '#send' do
    let(:message) { 'Test log message' }
    let(:level) { 'INFO' }
    let(:created_at) { Time.now.utc.iso8601 }
    let(:thread) { instance_spy(Thread) }

    before do
      stub_request(:post, "#{host}/logs")
      allow(Thread).to receive(:new).and_yield
    end

    it 'sends a log message in a new thread' do
      log_sync.send(message, level, created_at)
      sleep 0.01

      expect(a_request(:post, "#{host}/logs")).to have_been_made.once
    end

    context 'when api_key is nil' do
      let(:log_sync_no_key) { described_class.new(api_key: nil, host: host, verbose: verbose) }

      it 'does not send a log message' do
        log_sync_no_key.send(message, level, created_at)

        expect(a_request(:post, "#{host}/logs")).not_to have_been_made
      end

      it 'does not create a new thread' do
        log_sync_no_key.send(message, level, created_at)

        expect(Thread).not_to have_received(:new)
      end
    end

    it 'sends the correct payload body' do
      expected_body = {
        message: message,
        level: level,
        createdAt: created_at,
        sequenceNumber: 0
      }.to_json

      log_sync.send(message, level, created_at)
      sleep 0.01

      expect(a_request(:post, "#{host}/logs")
        .with(body: expected_body)).to have_been_made.once
    end

    it 'sends the correct headers' do
      log_sync.send(message, level, created_at)
      sleep 0.01

      expect(a_request(:post, "#{host}/logs")
        .with(headers: {
                'Content-Type' => 'application/json',
                'Project-Api-Key' => api_key
              })).to have_been_made.once
    end

    it 'increments the sequence number for each log' do
      log_sync.send(message, level, created_at)
      sleep 0.01
      log_sync.send(message, level, created_at)
      sleep 0.01

      expect(a_request(:post, "#{host}/logs")
        .with(body: hash_including(sequenceNumber: 1))).to have_been_made.once
    end

    it 'sends createdAt in iso8601 format' do
      formatted_time = Time.now.utc.iso8601
      log_sync.send(message, level, formatted_time)
      sleep 0.01

      expect(a_request(:post, "#{host}/logs")
               .with(body: hash_including(createdAt: formatted_time))).to have_been_made.once
    end

    context 'when verbose is true' do
      let(:verbose) { true }

      it 'outputs status on successful send' do
        stub_request(:post, "#{host}/logs").to_return(status: 200)
        expect do
          log_sync.send(message, level, created_at)
          sleep 0.01
        end
          .to output(a_string_starting_with('[LogDash BG] Sent log (seq: 0), status: 200')).to_stdout_from_any_process
      end
    end

    context 'when verbose is false' do
      let(:verbose) { false }

      it 'does not output status on successful send' do
        stub_request(:post, "#{host}/logs").to_return(status: 200)
        expect do
          log_sync.send(message, level, created_at)
          sleep 0.01
        end.not_to output.to_stdout_from_any_process
      end
    end
  end

  describe 'NoopLogSync' do
    let(:noop_log_sync) { Logdash::NoopLogSync.new }

    it 'does not make any HTTP requests' do
      noop_log_sync.send('Test log message', 'INFO', Time.now.utc.iso8601)

      expect(a_request(:any, /.*/)).not_to have_been_made
    end

    it 'does not create a new thread' do
      thread = instance_spy(Thread)
      allow(Thread).to receive(:new).and_return(thread)

      noop_log_sync.send('Test log message', 'INFO', Time.now.utc.iso8601)

      expect(Thread).not_to have_received(:new)
    end

    it 'does not output anything' do
      expect do
        noop_log_sync.send('Test log message', 'INFO', Time.now.utc.iso8601)
      end.not_to output.to_stdout_from_any_process
    end
  end
end
