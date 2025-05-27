# frozen_string_literal: true

require 'openai'

module MitchAI
  module AIProviders
    class OllamaProvider
      def initialize(api_key = nil)
        @api_key = api_key || ENV.fetch('OPENAI_API_KEY', nil)
        @client = OpenAI::Client.new(access_token: @api_key)
      end

      # rubocop:disable Metrics/MethodLength, Layout/LineLength
      def analyze_code(code, language)
        response = @client.chat(
          parameters: {
            model: 'gpt-3.5-turbo',
            messages: [
              {
                role: 'system',
                content: "You are a senior software engineer doing a code review. Analyze the following #{language} code and provide constructive feedback."
              },
              {
                role: 'user',
                content: "Please review this code and highlight:\n1. Potential bugs\n2. Performance improvements\n3. Best practice violations\n4. Suggested refactoring\n\nCode:\n#{code}"
              }
            ],
            max_tokens: 500
          }
        )

        parse_review_response(response)
      end
      # rubocop:enable Metrics/MethodLength, Layout/LineLength

      private

      def parse_review_response(response)
        {
          suggestions: response.dig('choices', 0, 'message', 'content'),
          raw_response: response
        }
      end
    end
  end
end
