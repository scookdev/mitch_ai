# frozen_string_literal: true

require_relative 'base_command'
require_relative '../mcp_server'

module MitchAI
  module Commands
    class ServerCommand < BaseCommand
      def call(args)
        action = args.first || 'start'
        port = extract_port(args)

        case action
        when 'start'
          start_server(port)
        when 'stop'
          stop_server(port)
        when 'status'
          show_status(port)
        when 'restart'
          stop_server(port)
          sleep(1)
          start_server(port)
        else
          puts "❌ Unknown server action: #{action}".red
          show_server_help
        end
      end

      private

      def start_server(port)
        if server_running?(port)
          puts "✅ MCP server already running on port #{port}".green
          return
        end

        puts "🚀 Starting MCP server on port #{port}...".cyan
        
        # Start server in background
        pid = Process.fork do
          begin
            MCPServer.start!(port)
          rescue StandardError => e
            puts "❌ Failed to start server: #{e.message}".red
            exit 1
          end
        end

        Process.detach(pid)
        
        # Wait a moment and check if it started
        sleep(2)
        
        if server_running?(port)
          puts "✅ MCP server started successfully on port #{port}".green
          puts "🔧 Available tools: #{get_server_tools(port).join(', ')}".white
          save_server_pid(pid, port)
        else
          puts "❌ Failed to start MCP server".red
        end
      end

      def stop_server(port)
        unless server_running?(port)
          puts "⚠️  MCP server not running on port #{port}".yellow
          return
        end

        pid = get_server_pid(port)
        if pid
          puts "🛑 Stopping MCP server (PID: #{pid})...".yellow
          Process.kill('TERM', pid.to_i)
          sleep(1)
          
          if server_running?(port)
            puts "🔨 Force stopping server...".red
            Process.kill('KILL', pid.to_i)
          end
          
          remove_server_pid(port)
          puts "✅ MCP server stopped".green
        else
          puts "⚠️  Could not find server process".yellow
        end
      end

      def show_status(port)
        if server_running?(port)
          puts "✅ MCP server running on port #{port}".green
          
          begin
            tools = get_server_tools(port)
            puts "🔧 Available tools (#{tools.length}): #{tools.join(', ')}".white
          rescue StandardError
            puts "⚠️  Server running but not responding to API calls".yellow
          end
        else
          puts "❌ MCP server not running on port #{port}".red
        end
      end

      def server_running?(port)
        system("curl -s http://localhost:#{port}/status > /dev/null 2>&1")
      end

      def get_server_tools(port)
        response = `curl -s http://localhost:#{port}/status`
        data = JSON.parse(response)
        data['tools'] || []
      rescue StandardError
        []
      end

      def extract_port(args)
        port_arg = args.find { |arg| arg.start_with?('--port=') }
        return port_arg.split('=').last.to_i if port_arg

        port_index = args.index('--port') || args.index('-p')
        return args[port_index + 1].to_i if port_index && args[port_index + 1]

        4568 # default port
      end

      def show_server_help
        puts <<~HELP
          #{'MCP Server Management'.cyan}

          #{'USAGE:'.yellow}
            mitch-ai server <action> [options]

          #{'ACTIONS:'.yellow}
            #{'start'.green}     Start the MCP server (default)
            #{'stop'.green}      Stop the MCP server  
            #{'status'.green}    Show server status
            #{'restart'.green}   Restart the MCP server

          #{'OPTIONS:'.yellow}
            #{'-p, --port=4568'.green}   Specify port (default: 4568)

          #{'EXAMPLES:'.yellow}
            mitch-ai server start
            mitch-ai server start --port=4569
            mitch-ai server status
            mitch-ai server stop
        HELP
      end

      def save_server_pid(pid, port)
        File.write("/tmp/mitch-ai-server-#{port}.pid", pid.to_s)
      end

      def get_server_pid(port)
        pid_file = "/tmp/mitch-ai-server-#{port}.pid"
        return nil unless File.exist?(pid_file)

        File.read(pid_file).strip
      end

      def remove_server_pid(port)
        pid_file = "/tmp/mitch-ai-server-#{port}.pid"
        File.delete(pid_file) if File.exist?(pid_file)
      end
    end
  end
end