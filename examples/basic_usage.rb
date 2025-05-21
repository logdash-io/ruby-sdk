# frozen_string_literal: true

require 'logdash'

puts '--- Basic Logging Example ---'

logdash_with_key = Logdash.create(api_key: 'YOUR_API_KEY_HERE', verbose: true)
logger_with_key = logdash_with_key[:logger]
metrics_with_key = logdash_with_key[:metrics]

logger_with_key.info('Logs info level')

puts "\n--- Logging Example (No API Key - Local Console Only) ---"
logdash_services_no_key = Logdash.create(verbose: true)
logger_no_key = logdash_services_no_key[:logger]

logger_no_key.info('Logs info level')
logger_no_key.error('Logs error level')
logger_no_key.warn('Logs warn level')
logger_no_key.debug('Logs debug level')

puts "\n--- Metrics Example (Requires API Key) ---"
metrics_with_key.set('active_users', 150)
metrics_with_key.mutate('login_attempts', 1)
metrics_with_key.mutate('login_attempts', 1)

puts "\n--- You can also instantiate the client directly ---"
client = Logdash.new_client(api_key: 'ANOTHER_API_KEY', verbose: true)
client.logger.info('Logging via directly instantiated client')
client.metrics.set('direct_client_metric', 5)
