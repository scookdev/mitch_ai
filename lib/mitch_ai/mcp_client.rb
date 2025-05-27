# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module MitchAI
  class MCPClient
    def initialize(server_url = 'http://localhost:4568')
      @server_url = server_url
      @request_id = 0
    end

    def call_tool(name, arguments = {})
      @request_id += 1

      message = {
        jsonrpc: '2.0',
        method: 'tools/call',
        params: { name: name, arguments: arguments },
        id: @request_id
      }

      uri = URI("#{@server_url}/mcp")
      response = Net::HTTP.post(uri, message.to_json, 'Content-Type' => 'application/json')
      result = JSON.parse(response.body)

      raise "MCP Error: #{result['error']['message']}" if result['error']

      result.dig('result', 'content', 0, 'text')
    end

    # File operations via MCP
    def read_file(path)
      call_tool('read_file', { path: path })
    end

    def list_ruby_files(path)
      JSON.parse(call_tool('find_ruby_files', { path: path }))
    end

    def git_diff(range = 'HEAD~1..HEAD')
      call_tool('git_diff', { range: range })
    end

    def detect_code_smells(content)
      JSON.parse(call_tool('detect_code_smells', { content: content }))
    end

    def analyze_complexity(path)
      JSON.parse(call_tool('analyze_complexity', { path: path }))
    end
  end
end
