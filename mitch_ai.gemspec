# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mitch_ai/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'mitch-ai'
  spec.version       = MitchAI::VERSION
  spec.authors       = ['Steve Cook']
  spec.email         = ['stevorevo@duck.com']

  spec.summary       = 'AI-powered code review assistant'
  spec.description = 'MitchAI is an intelligent CLI tool that leverages artificial intelligence to ' \
                     'provide comprehensive code reviews, helping developers improve code quality, ' \
                     'catch potential issues, and receive actionable insights.'
  spec.homepage      = 'https://github.com/scookdev/mitch_ai'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir = 'exe'
  spec.executables = ['mitch-ai']
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'thor', '~> 1.2'
  spec.add_dependency 'ruby-openai', '~> 3.7'
  spec.add_dependency 'tty-spinner', '~> 0.9.3'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'codecov', '~> 0.6.0'
  spec.add_development_dependency 'steep', '~> 1.5'
  spec.add_development_dependency 'pry-byebug', '~> 3.10'
end
# rubocop:enable Metrics/BlockLength
