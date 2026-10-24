# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

# Started before the library loads, so it measures lib instead of only the specs
SimpleCov.start { add_filter '/spec/' }

require 'logdash'
require 'timecop'
require 'webmock/rspec'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
