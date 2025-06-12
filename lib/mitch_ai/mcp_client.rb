# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module MitchAI
  class MCPError < StandardError; end
  class MCPConnectionError < MCPError; end
  class MCPServerError < MCPError; end

  class MCPClient
    CONTENT_TYPE = 'application/json'
    JSONRPC_VERSION = '2.0'

    def initialize(server_url = 'http://localhost:4568', http_client = Net::HTTP)
      @server_url = server_url
      @request_id = 0
      @http_client = http_client
    end

    def call_tool(name, arguments = {})
      response = make_request(name, arguments)
      parse_response(response)
    end

    def read_file(path)
      call_tool('read_file', { path: path })
    end

    def list_ruby_files(path)
      parse_json_response('find_ruby_files', { path: path })
    end

    def git_diff(range = 'HEAD~1..HEAD')
      call_tool('git_diff', { range: range })
    end

    def detect_code_smells(content)
      parse_json_response('detect_code_smells', { content: content })
    end

    def analyze_complexity(path)
      parse_json_response('analyze_complexity', { path: path })
    end

    private

    def make_request(name, arguments)
      uri = URI("#{@server_url}/mcp")
      message = build_message(name, arguments)

      @http_client.post(uri, message.to_json, 'Content-Type' => CONTENT_TYPE)
    rescue StandardError => e
      raise MCPConnectionError, "Failed to connect to MCP server: #{e.message}"
    end

    def parse_response(response)
      result = JSON.parse(response.body)
      handle_errors(result)
      result.dig('result', 'content', 0, 'text')
    rescue JSON::ParserError => e
      raise MCPServerError, "Invalid JSON response: #{e.message}"
    end

    def parse_json_response(tool_name, arguments)
      JSON.parse(call_tool(tool_name, arguments))
    rescue JSON::ParserError => e
      raise MCPServerError, "Invalid JSON in tool response: #{e.message}"
    end

    def handle_errors(result)
      return unless result['error']

      raise MCPServerError, "MCP Error: #{result['error']['message']}"
    end

    def build_message(name, arguments)
      @request_id += 1
      {
        jsonrpc: JSONRPC_VERSION,
        method: 'tools/call',
        params: { name: name, arguments: arguments },
        id: @request_id
      }
    end
  end
end
