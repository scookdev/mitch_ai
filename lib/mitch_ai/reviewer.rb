# frozen_string_literal: true

require_relative 'ollama_client'
require_relative 'mcp_client'
require_relative 'mcp_server'
require 'socket'
require 'json'
require 'ostruct'

module MitchAI
  class Reviewer
    DEFAULT_MODEL = 'deepseek-coder:6.7b'

    def initialize(
      model: DEFAULT_MODEL,
      ollama_url: 'http://localhost:11434',
      mcp_server_url: nil,
      external_mcp: false
    )
      @model = model
      @ollama = OllamaClient.new(ollama_url)
      @external_mcp = external_mcp

      if external_mcp
        # User is managing their own MCP server
        @mcp_server_url = mcp_server_url || 'http://localhost:4568'
        @mcp = MCPClient.new(@mcp_server_url)
      else
        # We manage the MCP server internally
        @mcp_server = start_internal_mcp_server
        @mcp_server_url = "http://localhost:#{@mcp_server.port}"
        @mcp = MCPClient.new(@mcp_server_url)
      end

      verify_connections!
    end

    # Enhanced file review with MCP + Ollama
    def review_file(file_path)
      # Get file content via MCP
      content = @mcp ? safe_mcp_call { @mcp.read_file(file_path) } : File.read(file_path)

      # Get additional context via MCP
      complexity = @mcp ? safe_mcp_call { @mcp.analyze_complexity(file_path) } : nil
      code_smells = @mcp ? safe_mcp_call { @mcp.detect_code_smells(content) } : nil

      # Prepare enhanced prompt for Ollama
      prompt = build_review_prompt(content, file_path, complexity, code_smells)

      # Get review from local Ollama
      review = get_ollama_review(prompt)

      {
        file_path: file_path,
        content_length: content.length,
        complexity_metrics: complexity,
        detected_smells: code_smells,
        ai_review: review,
        timestamp: Time.now.iso8601
      }
    end

    # Review entire project
    def review_project(project_path, _options = {})
      raise 'MCP required for project review' unless @mcp

      puts "🔍 Discovering Ruby files in #{project_path}..."
      ruby_files = safe_mcp_call { @mcp.list_ruby_files(project_path) } || []

      puts "📊 Found #{ruby_files.length} Ruby files to review"

      results = {}
      ruby_files.each_with_index do |file_path, index|
        puts "📝 Reviewing #{file_path} (#{index + 1}/#{ruby_files.length})"

        begin
          results[file_path] = review_file(file_path)
        rescue StandardError => e
          puts "❌ Error reviewing #{file_path}: #{e.message}"
          results[file_path] = { error: e.message }
        end
      end

      # Generate project summary
      summary = generate_project_summary(results)

      {
        project_path: project_path,
        total_files: ruby_files.length,
        summary: summary,
        detailed_results: results
      }
    end

    # Review git changes
    def review_git_changes(commit_range = 'HEAD~1..HEAD', project_path = '.')
      raise 'MCP required for git review' unless @mcp

      puts "🔄 Getting git diff for #{commit_range}..."
      diff = safe_mcp_call { @mcp.git_diff(commit_range) }

      return { error: 'Could not get git diff' } unless diff

      # Extract changed files
      changed_files = extract_ruby_files_from_diff(diff)

      puts "📋 Found #{changed_files.length} changed Ruby files"

      results = {}
      changed_files.each do |file_path|
        full_path = File.join(project_path, file_path)
        puts "🔍 Reviewing changed file: #{file_path}"

        begin
          if File.exist?(full_path)
            results[file_path] = review_file(full_path)
            results[file_path][:change_context] = extract_file_changes(diff, file_path)
          else
            results[file_path] = { error: "File not found: #{full_path}" }
          end
        rescue StandardError => e
          results[file_path] = { error: e.message }
        end
      end

      {
        commit_range: commit_range,
        diff_summary: summarize_diff(diff),
        changed_files: changed_files,
        detailed_reviews: results
      }
    end

    # Smart review that determines what to do based on input
    def smart_review(target)
      if File.file?(target)
        review_file(target)
      elsif File.directory?(target)
        review_project(target)
      elsif target.include?('..')
        # Looks like a git range
        review_git_changes(target)
      else
        raise "Unknown target type: #{target}"
      end
    end

    private

    def start_internal_mcp_server
      # Find available port
      port = find_available_port(4568)

      # Start server in background thread
      server_thread = Thread.new do
        require_relative 'mcp_server'
        MCPServer.set :port, port
        MCPServer.set :logging, false # Reduce noise
        MCPServer.run!
      end

      # Wait for server to be ready
      wait_for_server(port)

      # Return a simple object that tracks the port
      OpenStruct.new(port: port, thread: server_thread)
    end

    def find_available_port(starting_port)
      port = starting_port
      port += 1 while port_in_use?(port)
      port
    end

    def port_in_use?(port)
      TCPSocket.new('localhost', port).close
      true
    rescue Errno::ECONNREFUSED
      false
    end

    def wait_for_server(port, timeout: 10)
      start_time = Time.now

      loop do
        break if server_responding?(port)

        raise "MCP server failed to start within #{timeout} seconds" if Time.now - start_time > timeout

        sleep(0.1)
      end
    end

    def server_responding?(port)
      system("curl -s http://localhost:#{port}/status > /dev/null 2>&1")
    end

    def verify_connections!
      # Check Ollama connection
      begin
        @ollama.available_models
        puts '✅ Connected to Ollama'
      rescue StandardError => e
        puts "❌ Ollama connection failed: #{e.message}"
        puts '💡 Make sure Ollama is running: ollama serve'
        raise
      end

      # Check MCP connection
      if @mcp
        begin
          @mcp.call_tool('read_file', { path: __FILE__ })
          puts '✅ Connected to MCP server'
        rescue StandardError => e
          puts "❌ MCP connection failed: #{e.message}"
          puts '💡 MCP server may not be ready yet'
          # Don't raise - continue without MCP for basic functionality
          @mcp = nil
        end
      end

      # Check if model is available
      available_models = @ollama.available_models.map { |m| m['name'] }
      unless available_models.include?(@model)
        puts "❌ Model #{@model} not found"
        puts "📋 Available models: #{available_models.join(', ')}"
        puts "💡 Pull model with: ollama pull #{@model}"
        raise 'Model not available'
      end

      puts "✅ Using model: #{@model}"
    end

    def build_review_prompt(content, file_path, complexity, code_smells)
      <<~PROMPT
        You are an expert Ruby code reviewer. Please analyze this Ruby code and provide a comprehensive review.

        FILE: #{file_path}

        COMPLEXITY METRICS:
        #{complexity ? JSON.pretty_generate(JSON.parse(complexity)) : 'Not available'}

        DETECTED CODE SMELLS:
        #{code_smells ? JSON.pretty_generate(JSON.parse(code_smells)) : 'Not available'}

        CODE TO REVIEW:
        ```ruby
        #{content}
        ```

        Please provide a structured analysis with:
        1. Overall code quality score (1-10)
        2. Specific issues found (bugs, security, performance)
        3. Code style and best practices feedback
        4. Suggestions for improvement
        5. Positive aspects of the code

        Respond in JSON format with these keys:
        {
          "score": <number>,
          "issues": [<array of strings>],
          "suggestions": [<array of strings>],
          "positive_aspects": [<array of strings>],
          "summary": "<string>"
        }
      PROMPT
    end

    def get_ollama_review(prompt)
      messages = [
        {
          role: 'user',
          content: prompt
        }
      ]

      response = @ollama.chat(@model, messages)
      content = response.dig('message', 'content')

      # Try to parse as JSON, fallback to structured text
      begin
        JSON.parse(content)
      rescue JSON::ParserError
        # If not valid JSON, try to extract structured information
        parse_text_response(content)
      end
    rescue StandardError => e
      {
        error: "Failed to get AI review: #{e.message}",
        raw_response: content
      }
    end

    def parse_text_response(content)
      # Simple text parsing fallback
      lines = content.split("\n")

      {
        score: extract_score(content),
        issues: extract_section(content, 'issues'),
        suggestions: extract_section(content, 'suggestions'),
        positive_aspects: extract_section(content, 'positive'),
        summary: lines.last(3).join(' ').strip
      }
    end

    def extract_score(content)
      # Look for patterns like "Score: 7/10" or "7 out of 10"
      match = content.match(%r{(?:score|rating).*?(\d+)(?:/10|out of 10|\s*$)}i)
      match ? match[1].to_i : nil
    end

    def extract_section(content, keyword)
      lines = content.split("\n")
      section_lines = []
      in_section = false

      lines.each do |line|
        if line.downcase.include?(keyword)
          in_section = true
          next
        elsif in_section && (line.empty? || line.match(/^\d+\.|^-|^\*/))
          if line.strip.length > 3 # Ignore very short lines
            section_lines << line.strip.gsub(/^\d+\.\s*|^-\s*|^\*\s*/, '')
          end
        elsif in_section && line.match(/^[A-Z]/)
          break # New section started
        end
      end

      section_lines
    end

    def safe_mcp_call
      yield
    rescue StandardError => e
      puts "⚠️  MCP call failed: #{e.message}"
      nil
    end

    def generate_project_summary(results)
      successful_reviews = results.values.reject { |r| r[:error] }

      return { error: 'No successful reviews' } if successful_reviews.empty?

      # Calculate aggregate metrics
      scores = successful_reviews.filter_map { |r| r.dig(:ai_review, 'score') }
      avg_score = scores.any? ? scores.sum.to_f / scores.length : nil

      # Count issues
      total_issues = successful_reviews.sum do |r|
        issues = r.dig(:ai_review, 'issues')
        issues.is_a?(Array) ? issues.length : 0
      end

      {
        files_reviewed: successful_reviews.length,
        average_score: avg_score&.round(2),
        total_issues_found: total_issues,
        files_with_errors: results.count { |_, r| r[:error] }
      }
    end

    def extract_ruby_files_from_diff(diff)
      diff.scan(%r{\+\+\+ b/(.+\.rb)}).flatten
    end

    def extract_file_changes(diff, file_path)
      # Extract the specific changes for this file from the diff
      file_section = diff.split('diff --git').find { |section| section.include?(file_path) }
      file_section || 'Changes not found in diff'
    end

    def summarize_diff(diff)
      lines = diff.split("\n")
      {
        total_lines: lines.length,
        additions: lines.count { |l| l.start_with?('+') && !l.start_with?('+++') },
        deletions: lines.count { |l| l.start_with?('-') && !l.start_with?('---') },
        files_changed: diff.scan(%r{\+\+\+ b/(.+)}).flatten.length
      }
    end
  end
end
