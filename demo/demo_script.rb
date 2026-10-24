#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logdash'

seed = ENV.fetch('LOGDASH_SEED')
puts "=== LogDash SDK Demo: logdash #{Logdash::VERSION}, seed #{seed} ==="

logdash = Logdash.create(api_key: ENV.fetch('LOGDASH_API_KEY'), verbose: true)
logger = logdash[:logger]
metrics = logdash[:metrics]

# Each call returns the thread that sends it, which Ruby kills when the script ends, so the script waits for them.
# run.sh reads back a log of every level and demo_users at seed + 1, so the mutate goes out after the set arrived.
levels = %w[info error warn debug verbose http silly]
levels.map { |level| logger.public_send(level, 'smoke test', seed) }.each(&:join)
metrics.set('demo_users', seed.to_i).join
metrics.mutate('demo_users', 1).join
