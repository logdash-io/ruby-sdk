#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logdash'
require 'rubygems'

puts '=== LogDash SDK Demo ==='

# Get and display the logdash gem version
logdash_version = Gem.loaded_specs['logdash']&.version || 'unknown'
puts "Using logdash gem version: #{logdash_version}"
puts

api_key = ENV['LOGDASH_API_KEY'] || 'YOUR_API_KEY_HERE'
puts "Using API Key: #{api_key}"
logdash = Logdash.create(api_key: api_key, verbose: true)
logger = logdash[:logger]
metrics = logdash[:metrics]

logger.info('This is an info log')
logger.error('This is an error log')
metrics.set('demo_users', 42)
metrics.mutate('demo_counter', 1)

sleep 1 