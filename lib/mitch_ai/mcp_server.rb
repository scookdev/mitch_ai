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
      register_multi_language_tools
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

    def register_multi_language_tools
      # Enhanced project analysis
      register_tool(
        'analyze_project_structure',
        'Analyze entire project structure and recommend optimal model',
        { path: { type: 'string', description: 'Project root path' } }
      ) do |args|
        project_path = args['path'] || '.'
        detector = MitchAI::LanguageDetector.new(project_path)

        {
          languages_detected: detector.detect_languages,
          primary_language: detector.primary_language,
          project_type: detector.project_type,
          language_stats: detector.language_stats,
          recommended_model: recommend_model_for_project(detector)
        }.to_json
      end

      # Multi-language file finder
      register_tool(
        'find_all_source_files',
        'Find all source files grouped by language',
        {
          path: { type: 'string' },
          languages: { type: 'array', items: { type: 'string' }, required: false }
        }
      ) do |args|
        project_path = args['path'] || '.'
        target_languages = args['languages'] || []

        detector = MitchAI::LanguageDetector.new(project_path)
        languages = target_languages.empty? ? detector.detect_languages : target_languages.map(&:to_sym)

        results = {}
        languages.each do |language|
          results[language.to_s] = find_files_for_language(project_path, language)
        end

        JSON.generate(results)
      end

      # Language-specific analysis
      register_tool(
        'analyze_file_with_language',
        'Analyze a file with language-specific rules',
        {
          path: { type: 'string' },
          language: { type: 'string', required: false }
        }
      ) do |args|
        file_path = args['path']
        language = args['language']&.to_sym || detect_file_language(file_path)

        raise "File not found: #{file_path}" unless File.exist?(file_path)

        content = File.read(file_path)

        {
          file: file_path,
          language: language.to_s,
          complexity: analyze_complexity_for_language(content, language, file_path),
          smells: detect_smells_for_language(content, language),
          metrics: calculate_language_metrics(content, language)
        }.to_json
      end

      # Batch file analysis
      register_tool(
        'analyze_multiple_files',
        'Analyze multiple files efficiently',
        {
          files: { type: 'array', items: { type: 'string' } },
          language: { type: 'string', required: false }
        }
      ) do |args|
        files = args['files'] || []
        target_language = args['language']&.to_sym

        results = {}
        files.each do |file_path|
          next unless File.exist?(file_path)

          language = target_language || detect_file_language(file_path)
          content = File.read(file_path)

          results[file_path] = {
            language: language.to_s,
            complexity: analyze_complexity_for_language(content, language, file_path),
            smells: detect_smells_for_language(content, language),
            size: content.length
          }
        end

        JSON.generate(results)
      end
    end

    private

    def recommend_model_for_project(detector)
      languages = detector.detect_languages
      # Use SmartModelManager for consistent recommendations (defaults to fast tier)
      model_manager = MitchAI::SmartModelManager.new
      model_manager.recommend_model_for_languages(languages, tier: :fast)
    end

    def find_files_for_language(project_path, language)
      patterns = MitchAI::LanguageDetector::LANGUAGE_PATTERNS[language]
      return [] unless patterns

      extensions = patterns[:extensions]
      files = []

      Find.find(project_path) do |file_path|
        next unless File.file?(file_path)
        next if should_ignore_file?(file_path)

        files << file_path if extensions.any? { |ext| file_path.downcase.end_with?(ext.downcase) }
      end

      files
    rescue StandardError => e
      []
    end

    def detect_file_language(file_path)
      MitchAI::LanguageDetector.detect_language_from_extension(file_path)
    end

    def analyze_complexity_for_language(content, language, file_path)
      lines = content.lines
      base_metrics = {
        total_lines: lines.count,
        code_lines: lines.reject { |line| line.strip.empty? }.count,
        blank_lines: lines.count { |line| line.strip.empty? },
        file_size: content.bytesize
      }

      case language
      when :ruby
        base_metrics.merge(
          methods: content.scan(/^\s*def\s+/).count,
          classes: content.scan(/^\s*class\s+/).count,
          modules: content.scan(/^\s*module\s+/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('#') }
        )
      when :python
        base_metrics.merge(
          functions: content.scan(/^\s*def\s+/).count,
          classes: content.scan(/^\s*class\s+/).count,
          imports: content.scan(/^\s*(import|from)\s+/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('#') }
        )
      when :javascript, :typescript
        base_metrics.merge(
          functions: content.scan(/(function\s+\w+|const\s+\w+\s*=.*=>|\w+\s*:\s*function)/).count,
          classes: content.scan(/^\s*class\s+/).count,
          imports: content.scan(/^\s*(import|require)/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('//') || line.strip.start_with?('/*') }
        )
      when :go
        base_metrics.merge(
          functions: content.scan(/^\s*func\s+/).count,
          structs: content.scan(/^\s*type\s+\w+\s+struct/).count,
          interfaces: content.scan(/^\s*type\s+\w+\s+interface/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('//') }
        )
      when :rust
        base_metrics.merge(
          functions: content.scan(/^\s*fn\s+/).count,
          structs: content.scan(/^\s*struct\s+/).count,
          enums: content.scan(/^\s*enum\s+/).count,
          traits: content.scan(/^\s*trait\s+/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('//') }
        )
      when :css
        base_metrics.merge(
          selectors: content.scan(/[^{}]+\s*{/).count,
          rules: content.scan(/[^{}]*{[^{}]*}/).count,
          comment_lines: lines.count { |line| line.strip.start_with?('/*') || line.include?('*/') }
        )
      else
        base_metrics
      end
    end

    def detect_smells_for_language(content, language)
      case language
      when :ruby
        detect_ruby_smells(content)
      when :python
        detect_python_smells(content)
      when :javascript, :typescript
        detect_javascript_smells(content)
      when :go
        detect_go_smells(content)
      when :rust
        detect_rust_smells(content)
      when :css
        detect_css_smells(content)
      else
        ["Language #{language} analysis not yet implemented"]
      end
    end

    def detect_python_smells(content)
      smells = []
      lines = content.lines

      smells << "Long function (#{lines.count} lines)" if lines.count > 25
      smells << 'Missing docstring' unless content.match?(/""".*"""/m) || content.match?(/'''.*'''/m)
      smells << 'Star imports detected' if content.include?('from * import')
      smells << 'Bare except clause' if content.match?(/except:\s*$/)
      smells << 'Print statements (consider logging)' if content.match?(/\bprint\s*\(/)
      smells << 'Global variables detected' if content.match?(/^[A-Z_]+ = /)

      smells
    end

    def detect_javascript_smells(content)
      smells = []

      smells << 'Uses var instead of let/const' if content.match?(/\bvar\s+/)
      smells << 'Loose equality (==) detected' if content.include?('==') && !content.include?('===')
      smells << 'Console.log statements' if content.include?('console.log')
      smells << 'Callback nesting detected' if content.scan(/function.*{/).count > 3
      smells << 'Missing semicolons' if content.scan("\n").count > content.scan(/;\s*\n/).count * 1.5
      if content.match?(/var\s+\w+/) && !content.match?(/\w+\s*=/)
        smells << 'Unused variables (var declared but not used)'
      end

      smells
    end

    def detect_go_smells(content)
      smells = []

      smells << 'Missing error handling' if content.include?('err :=') && !content.include?('if err != nil')
      if content.match?(/import.*".*"/) && content.scan('import').count > content.scan(/\w+\./).count
        smells << 'Unused imports'
      end
      if content.match?(/^func [A-Z]/) && !content.match?(%r{//.*\n.*func [A-Z]})
        smells << 'Missing comments on exported functions'
      end
      smells << 'Long function' if content.lines.count > 30
      smells << 'Too many parameters' if content.match?(/func \w+\([^)]{50,}/)

      smells
    end

    def detect_rust_smells(content)
      smells = []

      smells << 'Unwrap() calls detected' if content.include?('.unwrap()')
      smells << 'Expect() calls detected' if content.include?('.expect(')
      if content.include?('Result<') && !content.include?('match') && !content.include?('?')
        smells << 'Missing error handling'
      end
      smells << 'Long function' if content.lines.count > 25
      smells << 'Clone() overuse' if content.scan('.clone()').count > 3
      smells << 'Unsafe blocks' if content.include?('unsafe {')

      smells
    end

    def detect_css_smells(content)
      smells = []

      smells << 'Important declarations (!important)' if content.include?('!important')
      smells << 'Inline styles detected' if content.include?('style=')
      smells << 'Deep nesting (>3 levels)' if content.scan(/\s{12,}/).any?
      smells << 'Magic numbers in CSS' if content.match?(/:\s*\d{3,}px/)
      smells << 'Vendor prefixes without autoprefixer' if content.match?(/-webkit-|-moz-|-ms-/)
      smells << 'Empty rules' if content.match?(/[^{}]+{\s*}/)

      smells
    end

    def calculate_language_metrics(content, language)
      case language
      when :ruby
        {
          ruby_version_detected: extract_ruby_version(content),
          rails_detected: content.include?('ActiveRecord') || content.include?('ApplicationController'),
          test_framework: detect_test_framework(content)
        }
      when :python
        {
          python_version_hints: extract_python_version_hints(content),
          framework_detected: detect_python_framework(content),
          async_code: content.include?('async def') || content.include?('await')
        }
      when :javascript, :typescript
        {
          es_version: detect_es_version(content),
          framework: detect_js_framework(content),
          typescript: language == :typescript
        }
      else
        {}
      end
    end

    def should_ignore_file?(path)
      ignore_patterns = [
        'node_modules/', '.git/', 'vendor/', 'target/', 'build/', 'dist/',
        '__pycache__/', '.pytest_cache/', 'coverage/', 'tmp/', 'log/',
        'spec/vcr_cassettes/', '.bundle/', 'pkg/'
      ]

      ignore_patterns.any? { |pattern| path.include?(pattern) }
    end

    # Helper methods for framework detection
    def detect_test_framework(content)
      return 'rspec' if content.include?('describe') || content.include?('it ')
      return 'minitest' if content.include?('assert') || content.include?('test_')

      'unknown'
    end

    def detect_python_framework(content)
      return 'django' if content.include?('django') || content.include?('models.Model')
      return 'flask' if content.include?('flask') || content.include?('@app.route')
      return 'fastapi' if content.include?('fastapi') || content.include?('@app.get')

      'none'
    end

    def detect_js_framework(content)
      return 'react' if content.include?('React') || content.include?('jsx')
      return 'vue' if content.include?('Vue') || content.include?('vue')
      return 'angular' if content.include?('angular') || content.include?('@Component')
      return 'node' if content.include?('require(') || content.include?('module.exports')

      'vanilla'
    end
  end
end
