# frozen_string_literal: true

require_relative 'mitch_ai/cli'
require_relative 'mitch_ai/version'
require_relative 'mitch_ai/ollama_client'
require_relative 'mitch_ai/mcp_client'
require_relative 'mitch_ai/reviewer'

module MitchAI
  class Error < StandardError; end

  def self.reviewer(options = {})
    Reviewer.new(options)
  end

  # Quick setup check
  def self.ready?
    ollama_running? && mcp_server_running?
  end

  def self.ollama_running?
    system('curl -s http://localhost:11434/api/version > /dev/null 2>&1')
  end

  def self.mcp_server_running?(port = 4568)
    system("curl -s http://localhost:#{port}/status > /dev/null 2>&1")
  end

  # Legacy reviewer for backward compatibility
  class LegacyReviewer
    def review(content, _options = {})
      # Your existing Mitch-AI logic goes here
      # This ensures existing users' code doesn't break

      {
        issues: analyze_issues(content),
        suggestions: generate_suggestions(content),
        score: calculate_score(content),
        legacy: true,
        message: "Using legacy mode. Run 'mitch-ai setup' for enhanced features."
      }
    end

    private

    def analyze_issues(_content)
      # Your existing issue detection logic
      []
    end

    def generate_suggestions(_content)
      # Your existing suggestion logic
      []
    end

    def calculate_score(_content)
      # Your existing scoring logic
      7.5
    end
  end
end
