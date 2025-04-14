# frozen_string_literal: true

require 'spec_helper'
require 'mitch_ai/analyzers/file_analyzer'

RSpec.describe MitchAI::Analyzers::FileAnalyzer do
  let(:ruby_file_path) { 'spec/fixtures/sample.rb' }
  let(:python_file_path) { 'spec/fixtures/sample.py' }
  let(:unknown_file_path) { 'spec/fixtures/unknown.xyz' }
  let(:ruby_code) { "def hello\n  puts 'world'\nend" }
  let(:python_code) { "def hello():\n  print('world')" }
  let(:mock_ai_provider) { instance_double(MitchAI::AIProviders::OpenAIProvider) }
  let(:mock_suggestions) { { suggestions: ['Suggestion 1', 'Suggestion 2'] } }
  let(:mock_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => "Suggestion 1: This could be improved.\n\nSuggestion 2: Consider refactoring this part."
          }
        }
      ]
    }
  end

  # rubocop:disable Layout/LineLength
  before do
    # Then in your mock AI provider
    allow(mock_ai_provider).to receive(:analyze_code).and_return({ suggestions: mock_response.dig('choices', 0, 'message',
                                                                                                  'content') })
    allow(MitchAI::AIProviders::OpenAIProvider).to receive(:new).and_return(mock_ai_provider)
    allow(mock_ai_provider).to receive(:analyze_code).and_return(mock_suggestions)

    # Create test files
    FileUtils.mkdir_p('spec/fixtures')
    File.write(ruby_file_path, ruby_code)
    File.write(python_file_path, python_code)
    File.write(unknown_file_path, 'unknown content')
  end
  # rubocop:enable Layout/LineLength

  after do
    # Clean up test files
    FileUtils.rm_rf('spec/fixtures')
  end

  describe '#initialize' do
    it 'sets the file path' do
      analyzer = described_class.new(ruby_file_path)
      expect(analyzer.instance_variable_get(:@file_path)).to eq(ruby_file_path)
    end

    it 'initializes an AI provider' do
      expect(MitchAI::AIProviders::OpenAIProvider).to receive(:new)
      described_class.new(ruby_file_path)
    end
  end

  describe '#analyze' do
    it 'detects Ruby language from file extension' do
      analyzer = described_class.new(ruby_file_path)
      result = analyzer.analyze

      expect(result[:language]).to eq('Ruby')
    end

    it 'detects Python language from file extension' do
      analyzer = described_class.new(python_file_path)
      result = analyzer.analyze

      expect(result[:language]).to eq('Python')
    end

    it 'defaults to Unknown for unrecognized file types' do
      analyzer = described_class.new(unknown_file_path)
      result = analyzer.analyze

      expect(result[:language]).to eq('Unknown')
    end

    it 'reads the file content' do
      expect(File).to receive(:read).with(ruby_file_path).and_return(ruby_code)

      analyzer = described_class.new(ruby_file_path)
      analyzer.analyze
    end

    it 'sends code to AI provider for analysis' do
      expect(mock_ai_provider).to receive(:analyze_code).with(ruby_code, 'Ruby').and_return(mock_suggestions)

      analyzer = described_class.new(ruby_file_path)
      analyzer.analyze
    end

    it 'returns a hash with file path, language and suggestions' do
      analyzer = described_class.new(ruby_file_path)
      result = analyzer.analyze

      expect(result).to be_a(Hash)
      expect(result).to include(
        file_path: ruby_file_path,
        language: 'Ruby',
        suggestions: ['Suggestion 1', 'Suggestion 2']
      )
    end

    it 'handles file read errors gracefully' do
      allow(File).to receive(:read).with(ruby_file_path).and_raise(Errno::ENOENT, 'File not found')

      analyzer = described_class.new(ruby_file_path)
      expect { analyzer.analyze }.to raise_error(RuntimeError, /Error reading file/)
    end
  end
end
