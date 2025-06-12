# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MitchAI::MCPClient do
  let(:mock_http_client) { double('Net::HTTP') }
  let(:client) { described_class.new('http://localhost:4568', mock_http_client) }
  let(:mock_response) { double('response', body: response_body) }

  describe '#initialize' do
    it 'sets default server URL' do
      default_client = described_class.new
      expect(default_client.instance_variable_get(:@server_url)).to eq('http://localhost:4568')
    end

    it 'accepts custom server URL and HTTP client' do
      custom_client = described_class.new('http://custom:9999', mock_http_client)
      expect(custom_client.instance_variable_get(:@server_url)).to eq('http://custom:9999')
      expect(custom_client.instance_variable_get(:@http_client)).to eq(mock_http_client)
    end
  end

  describe '#call_tool' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => 'file content' }]
        },
        'id' => 1
      }.to_json
    end

    it 'makes correct MCP request and returns result' do
      expect(mock_http_client).to receive(:post)
        .with(
          URI('http://localhost:4568/mcp'),
          hash_including(
            '"method":"tools/call"',
            '"params":{"name":"read_file","arguments":{"path":"/test/file.rb"}}'
          ),
          'Content-Type' => 'application/json'
        )
        .and_return(mock_response)

      result = client.call_tool('read_file', { path: '/test/file.rb' })
      expect(result).to eq('file content')
    end

    it 'increments request ID for each call' do
      allow(mock_http_client).to receive(:post).and_return(mock_response)

      client.call_tool('test1')
      client.call_tool('test2')

      # The request ID should increment
      expect(client.instance_variable_get(:@request_id)).to eq(2)
    end

    context 'when connection fails' do
      it 'raises MCPConnectionError' do
        expect(mock_http_client).to receive(:post)
          .and_raise(StandardError.new('Connection refused'))

        expect do
          client.call_tool('read_file', { path: '/test.rb' })
        end.to raise_error(MitchAI::MCPConnectionError, /Failed to connect to MCP server/)
      end
    end

    context 'when server returns error' do
      let(:response_body) do
        {
          'jsonrpc' => '2.0',
          'error' => { 'message' => 'File not found' },
          'id' => 1
        }.to_json
      end

      it 'raises MCPServerError' do
        expect(mock_http_client).to receive(:post).and_return(mock_response)

        expect do
          client.call_tool('read_file', { path: '/nonexistent.rb' })
        end.to raise_error(MitchAI::MCPServerError, 'MCP Error: File not found')
      end
    end

    context 'when response has invalid JSON' do
      let(:response_body) { 'invalid json' }

      it 'raises MCPServerError' do
        expect(mock_http_client).to receive(:post).and_return(mock_response)

        expect do
          client.call_tool('read_file', { path: '/test.rb' })
        end.to raise_error(MitchAI::MCPServerError, /Invalid JSON response/)
      end
    end
  end

  describe '#read_file' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => 'def hello\n  puts "world"\nend' }]
        },
        'id' => 1
      }.to_json
    end

    it 'calls read_file tool with path' do
      expect(mock_http_client).to receive(:post).and_return(mock_response)

      result = client.read_file('/path/to/file.rb')
      expect(result).to eq('def hello\n  puts "world"\nend')
    end
  end

  describe '#list_ruby_files' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => '["file1.rb", "file2.rb"]' }]
        },
        'id' => 1
      }.to_json
    end

    it 'returns parsed JSON array of files' do
      expect(mock_http_client).to receive(:post).and_return(mock_response)

      result = client.list_ruby_files('/path')
      expect(result).to eq(['file1.rb', 'file2.rb'])
    end

    context 'when tool returns invalid JSON' do
      let(:response_body) do
        {
          'jsonrpc' => '2.0',
          'result' => {
            'content' => [{ 'text' => 'invalid json' }]
          },
          'id' => 1
        }.to_json
      end

      it 'raises MCPServerError' do
        expect(mock_http_client).to receive(:post).and_return(mock_response)

        expect do
          client.list_ruby_files('/path')
        end.to raise_error(MitchAI::MCPServerError, /Invalid JSON in tool response/)
      end
    end
  end

  describe '#git_diff' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => 'diff --git a/file.rb b/file.rb...' }]
        },
        'id' => 1
      }.to_json
    end

    it 'uses default range when none provided' do
      expect(mock_http_client).to receive(:post)
        .with(anything, hash_including('"arguments":{"range":"HEAD~1..HEAD"}'), anything)
        .and_return(mock_response)

      client.git_diff
    end

    it 'uses custom range when provided' do
      expect(mock_http_client).to receive(:post)
        .with(anything, hash_including('"arguments":{"range":"HEAD~5..HEAD"}'), anything)
        .and_return(mock_response)

      client.git_diff('HEAD~5..HEAD')
    end
  end

  describe '#detect_code_smells' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => '{"smells": ["long_method", "duplicate_code"]}' }]
        },
        'id' => 1
      }.to_json
    end

    it 'returns parsed code smell analysis' do
      expect(mock_http_client).to receive(:post).and_return(mock_response)

      result = client.detect_code_smells('def long_method...')
      expect(result).to eq({ 'smells' => %w[long_method duplicate_code] })
    end
  end

  describe '#analyze_complexity' do
    let(:response_body) do
      {
        'jsonrpc' => '2.0',
        'result' => {
          'content' => [{ 'text' => '{"complexity": 8, "methods": []}' }]
        },
        'id' => 1
      }.to_json
    end

    it 'returns parsed complexity analysis' do
      expect(mock_http_client).to receive(:post).and_return(mock_response)

      result = client.analyze_complexity('/path/to/file.rb')
      expect(result).to eq({ 'complexity' => 8, 'methods' => [] })
    end
  end
end
