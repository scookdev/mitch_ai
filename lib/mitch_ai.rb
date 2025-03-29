# frozen_string_literal: true

require_relative 'mitch_ai/version'
require_relative 'mitch_ai/configuration'
require_relative 'mitch_ai/ai_providers/openai_provider'
require_relative 'mitch_ai/analyzers/file_analyzer'
require_relative 'mitch_ai/cli'

module MitchAI
  class Error < StandardError; end
end
