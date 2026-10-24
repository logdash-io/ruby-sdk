# frozen_string_literal: true

require 'spec_helper'
require 'logdash/events'
require 'open3'

RSpec.describe Logdash::Events do
  subject(:events) { described_class.new(api_key: api_key, host: host, verbose: false, app: app) }

  let(:api_key) { 'test_api_key' }
  let(:host) { 'https://test.logdash.io' }
  let(:app) { nil }
  let(:uuid_v4) { /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/ }

  before do
    stub_request(:post, "#{host}/events").to_return(status: 202)
  end

  describe '#track' do
    it 'posts the event to /events with the API key and a UUID v4 id' do
      events.track('agent_run', { model: 'opus', steps: 3, cached: true })
      events.flush
      expect(WebMock).to have_requested(:post, "#{host}/events")
        .with(headers: { 'Content-Type' => 'application/json', 'project-api-key' => api_key },
              body: { id: uuid_v4, name: 'agent_run', props: { model: 'opus', steps: 3, cached: true } }).once
    end

    it 'gives every event its own id' do
      ids = []
      stub_request(:post, "#{host}/events").to_return do |request|
        ids << JSON.parse(request.body)['id']
        { status: 202 }
      end
      2.times { events.track('agent_run') }
      events.flush
      expect(ids.uniq.size).to eq(2)
    end

    it 'sends the user id as a string' do
      events.track('agent_run', user_id: 42)
      events.flush
      expect(WebMock).to have_requested(:post, "#{host}/events").with(body: hash_including(userId: '42')).once
    end

    it 'takes keywords other than user_id as props, as Ruby < 3 passes a braced hash' do
      events.track('agent_run', model: 'opus', user_id: 42)
      events.flush
      expect(WebMock).to have_requested(:post, "#{host}/events")
        .with(body: hash_including(props: { model: 'opus' }, userId: '42')).once
    end

    context 'when app is set' do
      let(:app) { 'desktop' }

      it 'sends app in the payload body' do
        events.track('agent_run')
        events.flush
        expect(WebMock).to have_requested(:post, "#{host}/events").with(body: hash_including(app: 'desktop')).once
      end
    end

    context 'when app is empty' do
      let(:app) { '' }

      it 'does not send app' do
        events.track('agent_run')
        events.flush
        expect(WebMock).to have_requested(:post, "#{host}/events")
          .with { |request| !JSON.parse(request.body).key?('app') }.once
      end
    end

    ['Agent run', '', '9lives', 'a' * 65, "agent_run\n", 'pageview', 'browser_error', nil].each do |name|
      it "drops an event named #{name.inspect} with a warning", :aggregate_failures do
        expect { events.track(name) }.to output(/Dropping event .*its name must match/).to_stdout
        events.flush
        expect(WebMock).not_to have_requested(:post, "#{host}/events")
      end
    end

    it 'drops an event whose user id is an email address, without printing it', :aggregate_failures do
      expect { events.track('agent_run', user_id: 'alice@example.com') }
        .to output(/\A(?!.*@).*Dropping event "agent_run": user_id must be an internal ID/m).to_stdout
      events.flush
      expect(WebMock).not_to have_requested(:post, "#{host}/events")
    end

    it 'warns instead of raising when props cannot be sent' do
      expect { events.track('agent_run', { ratio: Float::NAN }) }.to output(/Dropping event "agent_run"/).to_stdout
    end

    it 'warns instead of raising when it cannot start a thread' do
      allow(Thread).to receive(:new).and_raise(ThreadError, "can't create Thread")
      expect { events.track('agent_run') }.to output(/Dropping event "agent_run": can't create Thread/).to_stdout
    end

    it 'does not raise into the app when the request fails' do
      stub_request(:post, "#{host}/events").to_timeout
      expect do
        events.track('agent_run')
        events.flush
      end.not_to raise_error
    end

    [nil, ''].each do |missing_key|
      context "when api_key is #{missing_key.inspect}" do
        let(:api_key) { missing_key }

        it 'prints the event to the local console only', :aggregate_failures do
          expect { events.track('agent_run', { model: 'opus' }) }
            .to output(a_string_including('Event agent_run {"model":"opus"}')).to_stdout
          events.flush
          expect(WebMock).not_to have_requested(:post, "#{host}/events")
        end
      end
    end
  end

  describe '#flush' do
    let(:script_that_tracks_and_exits) do
      <<~RUBY
        require 'webmock'
        WebMock.enable!
        WebMock::API.stub_request(:post, '#{host}/events').to_return do |request|
          sleep 0.2
          puts JSON.parse(request.body)['name']
          { status: 202 }
        end
        require 'logdash'
        Logdash::Events.new(api_key: 'key', host: '#{host}', verbose: false).track('agent_run')
      RUBY
    end

    it 'waits for the events still being sent' do
      sent = []
      stub_request(:post, "#{host}/events").to_return do |request|
        sleep 0.2
        sent << JSON.parse(request.body)['name']
        { status: 202 }
      end
      events.track('agent_run')
      events.flush
      expect(sent).to eq(['agent_run'])
    end

    it 'runs when the process exits' do
      lib = File.expand_path('../../lib', __dir__)
      stdout, stderr, = Open3.capture3(RbConfig.ruby, '-rbundler/setup', '-I', lib, '-e', script_that_tracks_and_exits)
      expect(stdout).to eq("agent_run\n"), stderr
    end
  end
end
