# frozen_string_literal: true

require 'find'

module MitchAI
  class LanguageDetector
    LANGUAGE_PATTERNS = {
      ruby: {
        extensions: ['.rb', '.rake', '.gemspec'],
        files: ['Gemfile', 'Rakefile', 'config.ru', 'Capfile'],
        directories: ['app/', 'lib/', 'spec/', 'test/', 'config/'],
        weight: 1.0
      },
      python: {
        extensions: ['.py', '.pyw', '.pyi'],
        files: ['requirements.txt', 'setup.py', 'pyproject.toml', 'Pipfile', 'poetry.lock'],
        directories: ['src/', 'tests/', '__pycache__/', '.pytest_cache/'],
        weight: 1.0
      },
      javascript: {
        extensions: ['.js', '.jsx', '.mjs', '.cjs'],
        files: ['package.json', '.eslintrc', '.eslintrc.js', '.eslintrc.json'],
        directories: ['src/', 'dist/', 'node_modules/', 'public/'],
        weight: 0.9
      },
      typescript: {
        extensions: ['.ts', '.tsx', '.d.ts'],
        files: ['tsconfig.json', 'tslint.json'],
        directories: ['src/', 'dist/', 'types/'],
        weight: 1.1
      },
      go: {
        extensions: ['.go'],
        files: ['go.mod', 'go.sum', 'Makefile'],
        directories: ['cmd/', 'pkg/', 'internal/', 'api/'],
        weight: 1.0
      },
      rust: {
        extensions: ['.rs'],
        files: ['Cargo.toml', 'Cargo.lock'],
        directories: ['src/', 'target/', 'tests/'],
        weight: 1.0
      },
      css: {
        extensions: ['.css', '.scss', '.sass', '.less'],
        files: [],
        directories: ['styles/', 'css/', 'assets/'],
        weight: 0.5
      },
      html: {
        extensions: ['.html', '.htm'],
        files: [],
        directories: ['public/', 'dist/', 'build/'],
        weight: 0.3
      },
      java: {
        extensions: ['.java'],
        files: ['pom.xml', 'build.gradle', 'build.gradle.kts'],
        directories: ['src/main/', 'src/test/', 'target/', 'build/'],
        weight: 1.0
      },
      cpp: {
        extensions: ['.cpp', '.cc', '.cxx', '.c', '.h', '.hpp'],
        files: ['CMakeLists.txt', 'Makefile'],
        directories: ['src/', 'include/', 'build/'],
        weight: 1.0
      }
    }.freeze

    def initialize(project_path)
      @project_path = File.expand_path(project_path)
    end

    def detect_languages
      return [] unless Dir.exist?(@project_path)

      language_scores = calculate_all_scores

      # Filter languages with meaningful presence
      detected = language_scores.select { |_, score| score > 0.2 }
                                .sort_by { |_, score| -score }
                                .map { |lang, _| lang }

      detected.empty? ? [:ruby] : detected
    end

    def primary_language
      detect_languages.first || :ruby
    end

    def language_stats
      stats = {}

      LANGUAGE_PATTERNS.each do |language, patterns|
        file_count = count_language_files(patterns[:extensions])
        stats[language] = {
          file_count: file_count,
          confidence: calculate_confidence(patterns),
          files: find_language_files(patterns[:extensions]).first(5) # Sample files
        }
      end

      stats.select { |_, data| data[:file_count] > 0 }
    end

    def project_type
      languages = detect_languages

      case languages
      when ->(langs) { langs.include?(:ruby) && langs.include?(:css) }
        :rails_fullstack
      when ->(langs) { langs.include?(:typescript) && langs.include?(:css) }
        :frontend_typescript
      when ->(langs) { langs.include?(:javascript) && langs.include?(:css) }
        :frontend_javascript
      when ->(langs) { langs.include?(:python) && langs.length == 1 }
        :python_backend
      when ->(langs) { langs.include?(:go) && langs.length <= 2 }
        :go_microservice
      when ->(langs) { langs.include?(:rust) }
        :rust_systems
      when ->(langs) { langs.include?(:java) }
        :java_enterprise
      else
        :mixed_project
      end
    end

    private

    def calculate_all_scores
      scores = {}

      LANGUAGE_PATTERNS.each do |language, patterns|
        scores[language] = calculate_confidence(patterns)
      end

      scores
    end

    def calculate_confidence(patterns)
      score = 0.0

      # Count files with matching extensions (primary signal)
      file_count = count_language_files(patterns[:extensions])
      score += file_count * 0.1 * patterns[:weight]

      # Check for specific files (strong signal)
      patterns[:files].each do |file|
        score += 0.5 * patterns[:weight] if File.exist?(File.join(@project_path, file))
      end

      # Check for directories (moderate signal)
      patterns[:directories].each do |dir|
        full_path = File.join(@project_path, dir)
        score += 0.2 * patterns[:weight] if Dir.exist?(full_path) && !Dir.empty?(full_path)
      end

      score
    end

    def count_language_files(extensions)
      return 0 if extensions.empty?

      count = 0
      Find.find(@project_path) do |path|
        next unless File.file?(path)

        # Skip common ignore patterns
        next if should_ignore_file?(path)

        count += 1 if extensions.any? { |ext| path.downcase.end_with?(ext.downcase) }
      end

      count
    rescue StandardError => e
      # Handle permission errors gracefully
      0
    end

    def find_language_files(extensions)
      files = []
      return files if extensions.empty?

      Find.find(@project_path) do |path|
        next unless File.file?(path)
        next if should_ignore_file?(path)

        files << path.sub(@project_path + '/', '') if extensions.any? { |ext| path.downcase.end_with?(ext.downcase) }

        break if files.length >= 20 # Limit for performance
      end

      files
    rescue StandardError => e
      []
    end

    def should_ignore_file?(path)
      ignore_patterns = [
        'node_modules/',
        '.git/',
        'vendor/',
        'target/',
        'build/',
        'dist/',
        '__pycache__/',
        '.pytest_cache/',
        'coverage/',
        '.coverage',
        'tmp/',
        'temp/',
        'log/',
        'spec/vcr_cassettes/',
        '.bundle/',
        'Gemfile.lock',
        'package-lock.json',
        'yarn.lock'
      ]

      ignore_patterns.any? { |pattern| path.include?(pattern) }
    end

    def self.detect_language_from_extension(file_path)
      ext = File.extname(file_path).downcase

      LANGUAGE_PATTERNS.each do |language, patterns|
        return language if patterns[:extensions].include?(ext)
      end

      # Special cases
      case File.basename(file_path)
      when 'Gemfile', 'Rakefile', 'config.ru'
        :ruby
      when 'package.json'
        :javascript
      when 'go.mod', 'go.sum'
        :go
      when 'Cargo.toml'
        :rust
      else
        :unknown
      end
    end
  end
end
