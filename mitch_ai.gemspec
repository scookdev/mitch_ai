lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mitch_ai/version'

Gem::Specification.new do |spec|
  spec.name          = 'mitch-ai'
  spec.version       = MitchAI::VERSION
  spec.authors       = ['Steve Cook']
  spec.email         = ['stevorevo@duck.com']

  spec.summary       = 'AI-powered code review assistant'
  spec.description   = 'A CLI tool that uses AI to provide intelligent code reviews'
  spec.homepage      = 'https://github.com/scookdev/mitch_ai'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'thor', '~> 1.2'
  spec.add_dependency 'ruby-openai', '~> 3.7'

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
