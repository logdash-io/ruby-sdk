#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logdash'

puts '=== LogDash SDK Demo ==='
puts

# Example with API key (sends data to LogDash servers)
puts '--- With API Key Example ---'
api_key = ENV['LOGDASH_API_KEY'] || 'YOUR_API_KEY_HERE'
puts "Using API Key: #{api_key}"
logdash = Logdash.create(api_key: api_key, verbose: true)
logger = logdash[:logger]
metrics = logdash[:metrics]

logger.info('This is an info log')
logger.error('This is an error log')
metrics.set('demo_users', 42)
metrics.mutate('demo_counter', 1)
puts

# Example without API key (logs to console only)
puts '--- Without API Key Example (Local Console Only) ---'
local_logdash = Logdash.create(verbose: true)
local_logger = local_logdash[:logger]

local_logger.info('Local info log')
local_logger.warn('Local warning log')
local_logger.debug('Local debug log')
puts

puts 'Demo completed!'

# Sleep for 1 second at the end
sleep 1 