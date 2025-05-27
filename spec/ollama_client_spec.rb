# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MitchAI::OllamaClient do
  let(:client) { described_class.new('http://localhost:11434') }

  describe '#chat' do
    it 'sends correct request to Ollama' do
      stub_request(:post, 'http://localhost:11434/api/chat')
        .with(
          body: hash_including(
            'model' => 'test-model',
            'messages' => [{ 'role' => 'user', 'content' => 'Hello' }]
          )
        )
        .to_return(
          status: 200,
          body: mock_ollama_response('Hello back!').to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      messages = [{ role: 'user', content: 'Hello' }]
      result = client.chat('test-model', messages)

      expect(result['message']['content']).to eq('Hello back!')
    end
  end

  describe '#available_models' do
    it 'fetches available models' do
      stub_request(:get, 'http://localhost:11434/api/tags')
        .to_return(
          status: 200,
          body: { 'models' => [{ 'name' => 'test-model' }] }.to_json
        )

      result = client.available_models
      expect(result).to eq([{ 'name' => 'test-model' }])
    end
  end
end
