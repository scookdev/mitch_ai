# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'

RSpec.describe MitchAI::MCPServer do
  include Rack::Test::Methods

  def app
    MitchAI::MCPServer
  end

  describe 'GET /status' do
    it 'returns server status' do
      get '/status'
      
      expect(last_response).to be_ok
      expect(last_response.content_type).to include('application/json')
      
      response_data = JSON.parse(last_response.body)
      expect(response_data).to include(
        'status' => 'running',
        'server' => 'Mitch-AI MCP Server',
        'version' => MitchAI::VERSION,
        'tools'
      )
      expect(response_data['tools']).to be_an(Array)
    end
  end

  describe 'POST /mcp' do
    context 'with initialize request' do
      it 'handles MCP initialization' do
        request_body = {
          jsonrpc: "2.0",
          method: "initialize",
          params: {
            protocolVersion: "2024-11-05",
            capabilities: {},
            clientInfo: { name: "Test Client", version: "1.0.0" }
          },
          id: 1
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 1
        )
        expect(response_data['result']).to include(
          'protocolVersion' => '2024-11-05',
          'capabilities',
          'serverInfo'
        )
        expect(response_data['result']['serverInfo']).to include(
          'name' => 'Mitch-AI MCP Server',
          'version' => MitchAI::VERSION
        )
      end
    end

    context 'with tools/list request' do
      it 'returns available tools' do
        request_body = {
          jsonrpc: "2.0",
          method: "tools/list",
          params: {},
          id: 2
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 2
        )
        expect(response_data['result']['tools']).to be_an(Array)
        
        # Check that default tools are present
        tool_names = response_data['result']['tools'].map { |t| t['name'] }
        expect(tool_names).to include('read_file', 'find_ruby_files', 'git_diff')
      end
    end

    context 'with tools/call request for read_file' do
      it 'reads an existing file' do
        # Create a temporary file for testing
        temp_file = Tempfile.new(['test', '.rb'])
        temp_file.write("puts 'Hello, World!'")
        temp_file.close

        request_body = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: {
            name: "read_file",
            arguments: { path: temp_file.path }
          },
          id: 3
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 3
        )
        expect(response_data['result']['content'][0]['text']).to eq("puts 'Hello, World!'")
        
        temp_file.unlink
      end

      it 'handles file not found error' do
        request_body = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: {
            name: "read_file",
            arguments: { path: "/nonexistent/file.rb" }
          },
          id: 4
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 4
        )
        expect(response_data['error']).to include(
          'code' => -32603,
          'message'
        )
        expect(response_data['error']['message']).to include('File not found')
      end
    end

    context 'with tools/call request for analyze_complexity' do
      it 'analyzes code complexity' do
        # Create a temporary Ruby file
        temp_file = Tempfile.new(['test', '.rb'])
        ruby_code = <<~RUBY
          class Calculator
            # This is a comment
            def add(a, b)
              a + b
            end

            def subtract(a, b)
              a - b
            end
          end
        RUBY
        temp_file.write(ruby_code)
        temp_file.close

        request_body = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: {
            name: "analyze_complexity",
            arguments: { path: temp_file.path }
          },
          id: 5
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 5
        )
        
        complexity_data = JSON.parse(response_data['result']['content'][0]['text'])
        expect(complexity_data).to include(
          'lines_of_code',
          'blank_lines',
          'comment_lines',
          'methods',
          'classes'
        )
        expect(complexity_data['methods']).to eq(2)
        expect(complexity_data['classes']).to eq(1)
        expect(complexity_data['comment_lines']).to eq(1)
        
        temp_file.unlink
      end
    end

    context 'with tools/call request for detect_code_smells' do
      it 'detects code smells' do
        smelly_code = <<~RUBY
          def long_method_with_many_parameters(a, b, c, d, e, f)
            # This method is too long and has too many parameters
            puts a
            puts b
            puts c
            puts d
            puts e
            puts f
            puts "line 8"
            puts "line 9"
            puts "line 10"
            puts "line 11"
            puts "line 12"
            puts "line 13"
            puts "line 14"
            puts "line 15"
            puts "line 16"
            puts "line 17"
            puts "line 18"
            puts "line 19"
            puts "line 20"
            puts "line 21"
            puts "line 22"
            puts "line 23"
          end
        RUBY

        request_body = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: {
            name: "detect_code_smells",
            arguments: { content: smelly_code }
          },
          id: 6
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'id' => 6
        )
        
        smells = JSON.parse(response_data['result']['content'][0]['text'])
        expect(smells).to be_an(Array)
        expect(smells.any? { |smell| smell.include?('Long method') }).to be true
        expect(smells.any? { |smell| smell.include?('Long parameter list') }).to be true
      end
    end

    context 'with tools/call request for find_ruby_files' do
      it 'finds Ruby files in directory' do
        # Create a temporary directory structure
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, 'test1.rb'), 'puts "test1"')
          File.write(File.join(dir, 'test2.rb'), 'puts "test2"')
          File.write(File.join(dir, 'readme.txt'), 'Not a Ruby file')
          
          # Create subdirectory
          subdir = File.join(dir, 'subdir')
          Dir.mkdir(subdir)
          File.write(File.join(subdir, 'test3.rb'), 'puts "test3"')

          request_body = {
            jsonrpc: "2.0",
            method: "tools/call",
            params: {
              name: "find_ruby_files",
              arguments: { path: dir }
            },
            id: 7
          }

          post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
          
          expect(last_response).to be_ok
          response_data = JSON.parse(last_response.body)
          
          ruby_files = JSON.parse(response_data['result']['content'][0]['text'])
          expect(ruby_files).to be_an(Array)
          expect(ruby_files.length).to eq(3)
          expect(ruby_files.all? { |f| f.end_with?('.rb') }).to be true
        end
      end
    end

    context 'with invalid JSON' do
      it 'handles parse errors' do
        post '/mcp', 'invalid json', { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(400)
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'error' => {
            'code' => -32700,
            'message' => 'Parse error'
          },
          'id' => nil
        )
      end
    end

    context 'with unknown method' do
      it 'returns method not found error' do
        request_body = {
          jsonrpc: "2.0",
          method: "unknown/method",
          params: {},
          id: 8
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'error' => {
            'code' => -32601,
            'message' => 'Method not found'
          },
          'id' => 8
        )
      end
    end

    context 'with unknown tool' do
      it 'returns tool not found error' do
        request_body = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: {
            name: "nonexistent_tool",
            arguments: {}
          },
          id: 9
        }

        post '/mcp', request_body.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response).to be_ok
        response_data = JSON.parse(last_response.body)
        
        expect(response_data).to include(
          'jsonrpc' => '2.0',
          'error' => {
            'code' => -32602,
            'message' => 'Tool not found: nonexistent_tool'
          },
          'id' => 9
        )
      end
    end
  end

  describe 'CORS headers' do
    it 'includes CORS headers in response' do
      get '/status'
      
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(last_response.headers['Access-Control-Allow-Methods']).to include('GET', 'POST')
      expect(last_response.headers['Access-Control-Allow-Headers']).to include('Content-Type')
    end

    it 'handles OPTIONS preflight request' do
      options '/mcp'
      
      expect(last_response).to be_ok
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end
end
