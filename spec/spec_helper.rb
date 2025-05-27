# frozen_string_literal: true

require 'bundler/setup'
require 'mitch_ai'
require 'webmock/rspec'
require 'vcr'
require 'rack/test'
require 'tempfile'
require 'tmpdir'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Helper method to check if test environment is available
  config.before(:suite) do
    # Check if Ollama is running for integration tests
    if (ENV['INTEGRATION_TESTS'] == 'true') && !system('curl -s http://localhost:11434/api/version > /dev/null 2>&1')
      puts 'Warning: Ollama not running. Some tests may be skipped.'
    end
  end
end

# Test helpers
module TestHelpers
  def mock_ollama_response(content)
    {
      'message' => {
        'content' => content
      }
    }
  end

  def mock_mcp_response(result)
    {
      'jsonrpc' => '2.0',
      'result' => {
        'content' => [
          {
            'type' => 'text',
            'text' => result
          }
        ]
      },
      'id' => 1
    }
  end

  def sample_ruby_code
    <<~RUBY
      class Calculator
        def add(a, b)
          a + b
        end
      #{'  '}
        def divide(a, b)
          a / b  # Potential division by zero
        end
      end
    RUBY
  end

  def sample_review_result
    {
      score: 7,
      issues: ['Potential division by zero in divide method'],
      suggestions: ['Add validation for b != 0 before division'],
      positive_aspects: ['Clean, readable code structure'],
      summary: 'Good basic implementation with one safety issue'
    }
  end
end

RSpec.configure do |config|
  config.include TestHelpers
  config.include Rack::Test::Methods, type: :request
end
