# logdash - Ruby SDK

Logdash is a zero-config observability platform. This package serves as a Ruby interface to use it.

## Pre-requisites

Setup your free project in less than 2 minutes at [logdash.io](https://logdash.io/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logdash'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install logdash
```

## Logging

```ruby
require 'logdash'

logdash_client = Logdash.create(api_key: "YOUR_API_KEY")
logger = logdash_client[:logger]

logger.info('Application started successfully')
logger.error('An unexpected error occurred')
logger.warn('Low disk space warning')
logger.debug('Debugging information')
logger.verbose('Verbose logging')
logger.http('HTTP request details')
logger.silly('Silly level logging')
```

## Metrics

```ruby
require 'logdash'

logdash_client = Logdash.create(api_key: "YOUR_API_KEY")
metrics = logdash_client[:metrics]

metrics.set('users', 0)
metrics.mutate('users', 1)
```

## Events

```ruby
require 'logdash'

logdash_client = Logdash.create(api_key: "YOUR_API_KEY")
events = logdash_client[:events]

events.track('agent_run', { agent: 'support', steps: 4, success: true }, user_id: current_user.id)
```

Events show up in your domain's Analytics as goals, with a daily trend.
Pass `user_id` for signed-in users, so one person counts once across your website and apps.
Without it, Logdash counts a visitor of that app that changes every day.
Never put personal data in props.

Events are sent in the background, and a script waits for them before it exits.
Call `events.flush` to wait for them sooner, for example before a serverless function returns.

## Ruby on Rails

In a Ruby on Rails application, you can use an initializer to configure Logdash. Create a new file in `config/initializers/logdash.rb` with the following content:

```ruby
require 'logdash'

ActiveSupport.on_load(:after_initialize) do
  $logdash_client = Logdash.create(api_key: "YOUR_API_KEY")
  $logger = $logdash_client[:logger]
  $metrics = $logdash_client[:metrics]
  $events = $logdash_client[:events]
end
```

This will make `$logger`, `$metrics` and `$events` available throughout your Ruby on Rails application.

## Configuration

| Parameter | Required | Default                  | Description                                                                                                     |
| --------- | -------- | ------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `api_key` | no       | -                        | API key used to authorize against Logdash servers. Without one, logs and events print to the local console only |
| `host`    | no       | `https://api.logdash.io` | Custom API host, useful with self-hosted instances                                                              |
| `verbose` | no       | `false`                  | Useful for debugging purposes                                                                                   |
| `app`     | no       | -                        | Name of the app sending logs, metrics and events. See [Apps](#apps)                                             |

### Apps

A domain key is shared by all apps of a domain, for example a desktop app, an API and a landing page.
`app` names the app this client runs in, so the dashboard can filter logs, metrics and events by app:

```ruby
logdash_client = Logdash.create(api_key: "YOUR_DOMAIN_KEY", app: "api")
```

Logdash creates the app on first use.
Older service keys ignore `app`.

## View

To see the logs or metrics, go to your project dashboard

![logs](docs/logs.png)
![delta](docs/delta.png)

## License

This project is licensed under the MIT License. See `LICENSE` for more information.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

### Running Tests

Before submitting a PR, please run the test suite and rubocop:

```bash
bundle exec rspec
bundle exec rubocop
```

## Support

If you encounter any issues, please open an issue on GitHub or let us know at [contact@logdash.io](mailto:contact@logdash.io).
