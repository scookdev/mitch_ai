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

  spec.summary       = 'AI-powered code review with local models and zero API costs'
  spec.description   = <<~DESC
    Mitch-AI is an advanced code review tool that combines local AI models (via Ollama)
    with the Model Context Protocol (MCP) to provide comprehensive, private code analysis.

    NEW in 1.0: 100% local AI processing, zero API costs, complete privacy, git integration,
    project-wide analysis, and continuous monitoring capabilities.

    Features:
    - Local AI models (no cloud API required)
    - Complete privacy (code never leaves your machine)#{'  '}
    - Git integration for reviewing changes
    - Project-wide analysis
    - Continuous monitoring
    - Extensible architecture via MCP
    - Backward compatible with existing API
  DESC

  spec.homepage      = 'https://github.com/scookdev/mitch_ai'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = "#{spec.homepage}#readme"

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = ['mitch-ai']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  # ================================
  # RUNTIME DEPENDENCIES
  # ================================

  spec.add_dependency 'colorize'
  spec.add_dependency 'json', '~> 2.0'             # JSON processing
  spec.add_dependency 'puma', '~> 6.0'             # Web server for MCP
  spec.add_dependency 'sinatra', '~> 3.0'          # MCP server
  spec.add_dependency 'tty-spinner', '~> 0.9.3'    # Great for progress indicators

  # ================================
  # DEVELOPMENT DEPENDENCIES
  # ================================

  # Keep all your existing dev dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'codecov', '~> 0.6.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'redcarpet', '~> 3.6' # YARD markdown support
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rspec-json_expectations', '~> 2.2' # For JSON testing
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'steep', '~> 1.5'
  spec.add_development_dependency 'vcr', '~> 6.1' # For recording HTTP interactions
  spec.add_development_dependency 'webmock', '~> 3.18' # For testing HTTP calls
  spec.add_development_dependency 'yard', '~> 0.9' # Documentation
  spec.post_install_message = <<~MSG
    🎉 Mitch-AI 1.0.0 has been installed!

    🚀 NEW: Local AI-powered code review with zero API costs!

    Quick start:
      1. Run: mitch-ai setup
      2. Then: mitch-ai review /path/to/your/code

    This will install Ollama, download a code model, and start reviewing!

    📖 Documentation: #{spec.homepage}
    🆘 Need help? Run: mitch-ai --help
  MSG
end
# rubocop:enable Metrics/BlockLength
