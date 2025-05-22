# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logdash/version'

Gem::Specification.new do |spec|
  spec.name          = 'logdash'
  spec.version       = Logdash::VERSION
  spec.authors       = ['krzysztoff1']
  spec.email         = ['hello@krzysztof.studio']

  spec.summary       = 'Ruby client for LogDash observability platform.'
  spec.description   = 'A Ruby client to send logs and metrics to the LogDash.'
  spec.homepage      = 'https://logdash.io/'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/logdash-io/ruby-sdk'
  spec.metadata['changelog_uri'] = 'https://github.com/logdash-io/ruby-sdk/blob/main/CHANGELOG.md'

  spec.files = Dir.glob('lib/**/*.rb') + %w[LICENSE README.md CHANGELOG.md .rubocop.yml]
  spec.bindir        = 'exe'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.62'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.25'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
