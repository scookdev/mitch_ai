# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MitchAI::MCPClient do
  let(:client) { described_class.new('http://localhost:4568') }

  describe '#call_tool' do
    it 'makes correct MCP request', :vcr do
      stub_request(:post, 'http://localhost:4568/mcp')
        .with(
          body: hash_including(
            'method' => 'tools/call',
            'params' => {
              'name' => 'read_file',
              'arguments' => { 'path' => '/test/file.rb' }
            }
          )
        )
        .to_return(
          status: 200,
          body: mock_mcp_response('file content').to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.call_tool('read_file', { path: '/test/file.rb' })
      expect(result).to eq('file content')
    end

    it 'handles MCP errors gracefully' do
      stub_request(:post, 'http://localhost:4568/mcp')
        .to_return(
          status: 200,
          body: {
            'jsonrpc' => '2.0',
            'error' => { 'message' => 'File not found' },
            'id' => 1
          }.to_json
        )

      expect do
        client.call_tool('read_file', { path: '/nonexistent.rb' })
      end.to raise_error('MCP Error: File not found')
    end
  end
end
