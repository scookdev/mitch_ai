# frozen_string_literal: true

require 'spec_helper'
require 'mitch_ai/ai_providers/openai_provider'

RSpec.describe MitchAI::AIProviders::OpenAIProvider do
  let(:api_key) { 'test_api_key' }
  let(:code_sample) { "def hello\n  puts 'world'\nend" }
  let(:language) { 'Ruby' }
  let(:mock_client) { instance_double(OpenAI::Client) }
  let(:mock_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => 'This code looks good, but consider adding a docstring.'
          }
        }
      ],
      'usage' => {
        'total_tokens' => 150
      }
    }
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:chat).and_return(mock_response)
  end

  describe '#initialize' do
    it 'uses the provided API key' do
      expect(OpenAI::Client).to receive(:new).with(access_token: api_key)
      described_class.new(api_key)
    end

    it 'falls back to ENV variable when no API key is provided' do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('env_api_key')

      expect(OpenAI::Client).to receive(:new).with(access_token: 'env_api_key')
      described_class.new
    end
  end

  describe '#analyze_code' do
    let(:provider) { described_class.new(api_key) }

    # rubocop:disable Layout/LineLength
    it 'sends a properly formatted request to the OpenAI API' do
      expected_params = {
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'system',
              content: 'You are a senior software engineer doing a code review. Analyze the following Ruby code and provide constructive feedback.'
            },
            {
              role: 'user',
              content: "Please review this code and highlight:\n1. Potential bugs\n2. Performance improvements\n3. Best practice violations\n4. Suggested refactoring\n\nCode:\ndef hello\n  puts 'world'\nend"
            }
          ],
          max_tokens: 500
        }
      }
      # rubocop:enable Layout/LineLength

      expect(mock_client).to receive(:chat).with(expected_params).and_return(mock_response)
      provider.analyze_code(code_sample, language)
    end

    it 'includes the language in the system prompt' do
      expect(mock_client).to receive(:chat) do |args|
        system_message = args[:parameters][:messages][0][:content]
        expect(system_message).to include(language)
        mock_response
      end

      provider.analyze_code(code_sample, language)
    end

    it 'returns a hash with suggestions and raw response' do
      result = provider.analyze_code(code_sample, language)

      expect(result).to be_a(Hash)
      expect(result).to include(
        suggestions: 'This code looks good, but consider adding a docstring.',
        raw_response: mock_response
      )
    end

    it 'handles API errors gracefully' do
      error_response = { 'error' => { 'message' => 'Invalid API key' } }
      allow(mock_client).to receive(:chat).and_return(error_response)

      result = provider.analyze_code(code_sample, language)
      expect(result[:suggestions]).to be_nil
    end

    it 'handles unexpected response formats gracefully' do
      allow(mock_client).to receive(:chat).and_return({})

      result = provider.analyze_code(code_sample, language)
      expect(result[:suggestions]).to be_nil
    end
  end
end
