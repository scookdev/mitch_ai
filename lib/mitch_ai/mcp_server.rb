# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'logger'

module MitchAI
  class MCPServer < Sinatra::Base
    configure do
      set :port, 4568
      set :bind, '0.0.0.0'
      set :protection, except: [:json_csrf]
      enable :cross_origin
    end

    before do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
      content_type :json
    end

    def initialize(app = nil)
      super
      @logger = Logger.new($stdout)
      @tools = {}
      register_code_review_tools
    end

    # MCP Protocol endpoint
    post '/mcp' do
      request_body = JSON.parse(request.body.read)
      response = handle_mcp_message(request_body)
      response.to_json
    rescue JSON::ParserError
      status 400
      { jsonrpc: '2.0', error: { code: -32_700, message: 'Parse error' }, id: nil }.to_json
    rescue StandardError => e
      @logger.error "Error: #{e.message}"
      status 500
      { jsonrpc: '2.0', error: { code: -32_603, message: 'Internal error' }, id: nil }.to_json
    end

    get '/status' do
      {
        status: 'running',
        server: 'Mitch-AI MCP Server',
        version: MitchAI::VERSION,
        tools: @tools.keys
      }.to_json
    end

    private

    def handle_mcp_message(message)
      method = message['method']
      params = message['params'] || {}
      id = message['id']

      case method
      when 'initialize'
        {
          jsonrpc: '2.0',
          result: {
            protocolVersion: '2024-11-05',
            capabilities: { tools: {}, resources: {} },
            serverInfo: { name: 'Mitch-AI MCP Server', version: MitchAI::VERSION }
          },
          id: id
        }
      when 'tools/list'
        {
          jsonrpc: '2.0',
          result: { tools: @tools.values.map { |t| t.except(:handler) } },
          id: id
        }
      when 'tools/call'
        call_tool(params['name'], params['arguments'] || {}, id)
      else
        {
          jsonrpc: '2.0',
          error: { code: -32_601, message: 'Method not found' },
          id: id
        }
      end
    end

    def call_tool(tool_name, arguments, id)
      if @tools.key?(tool_name)
        begin
          result = @tools[tool_name][:handler].call(arguments)
          {
            jsonrpc: '2.0',
            result: { content: [{ type: 'text', text: result.to_s }] },
            id: id
          }
        rescue StandardError => e
          {
            jsonrpc: '2.0',
            error: { code: -32_603, message: "Tool execution failed: #{e.message}" },
            id: id
          }
        end
      else
        {
          jsonrpc: '2.0',
          error: { code: -32_602, message: "Tool not found: #{tool_name}" },
          id: id
        }
      end
    end

    def register_tool(name, description, parameters = {}, &block)
      @tools[name] = {
        name: name,
        description: description,
        inputSchema: {
          type: 'object',
          properties: parameters,
          required: parameters.keys
        },
        handler: block
      }
    end

    def register_code_review_tools
      # Read file tool
      register_tool(
        'read_file',
        'Read contents of a file',
        { path: { type: 'string', description: 'File path to read' } }
      ) do |args|
        path = args['path']
        raise "File not found: #{path}" unless File.exist?(path)
        raise "File not readable: #{path}" unless File.readable?(path)

        File.read(path)
      end

      # Find Ruby files tool
      register_tool(
        'find_ruby_files',
        'Find all Ruby files in project',
        {
          path: { type: 'string', description: 'Project root path' },
          exclude_patterns: { type: 'array', description: 'Patterns to exclude' }
        }
      ) do |args|
        path = args['path']
        exclude_patterns = args['exclude_patterns'] || ['vendor/', 'tmp/', '.git/']

        raise "Directory not found: #{path}" unless Dir.exist?(path)

        ruby_files = Dir.glob("#{path}/**/*.rb").reject do |file|
          exclude_patterns.any? { |pattern| file.include?(pattern) }
        end

        ruby_files.to_json
      end

      # Git diff tool
      register_tool(
        'git_diff',
        'Get git diff for specified range',
        { range: { type: 'string', description: 'Git commit range' } }
      ) do |args|
        range = args['range'] || 'HEAD~1..HEAD'

        Dir.chdir(Dir.pwd) do
          raise 'Not a git repository' unless Dir.exist?('.git')

          `git diff #{range}`
        end
      end

      # Code complexity analysis
      register_tool(
        'analyze_complexity',
        'Analyze code complexity metrics',
        { path: { type: 'string', description: 'File path to analyze' } }
      ) do |args|
        path = args['path']
        raise "File not found: #{path}" unless File.exist?(path)

        content = File.read(path)
        lines = content.lines

        {
          lines_of_code: lines.count,
          blank_lines: lines.count { |line| line.strip.empty? },
          comment_lines: lines.count { |line| line.strip.start_with?('#') },
          methods: content.scan(/^\s*def\s+/).count,
          classes: content.scan(/^\s*class\s+/).count,
          modules: content.scan(/^\s*module\s+/).count
        }.to_json
      end

      # Code smell detection
      register_tool(
        'detect_code_smells',
        'Detect common code smells in Ruby code',
        { content: { type: 'string', description: 'Ruby code content to analyze' } }
      ) do |args|
        content = args['content']
        smells = []

        # Long method detection
        methods = content.scan(/def\s+\w+.*?^end/m)
        methods.each do |method|
          smells << "Long method detected (#{method.lines.count} lines)" if method.lines.count > 20
        end

        # Long parameter list
        content.scan(/def\s+\w+\(([^)]+)\)/) do |params|
          param_count = params[0].split(',').count
          smells << "Long parameter list (#{param_count} parameters)" if param_count > 4
        end

        smells.to_json
      end
    end

    def self.start!(port = 4568)
      set :port, port
      run!
    end
  end
end
