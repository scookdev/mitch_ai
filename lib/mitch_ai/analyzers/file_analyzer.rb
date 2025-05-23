# frozen_string_literal: true

module MitchAI
  module Analyzers
    class FileAnalyzer
      # Simple mapping of file extensions to languages
      LANGUAGE_MAP = {
        '.rb' => 'Ruby',
        '.py' => 'Python',
        '.js' => 'JavaScript',
        '.html' => 'HTML',
        '.css' => 'CSS',
        '.java' => 'Java',
        '.c' => 'C',
        '.cpp' => 'C++',
        '.cc' => 'C++',
        '.cxx' => 'C++',
        '.h' => 'C/C++ Header',
        '.hpp' => 'C++ Header',
        '.cs' => 'C#',
        '.php' => 'PHP',
        '.go' => 'Go',
        '.rs' => 'Rust',
        '.ts' => 'TypeScript',
        '.jsx' => 'React JSX',
        '.tsx' => 'React TSX',
        '.swift' => 'Swift',
        '.kt' => 'Kotlin',
        '.scala' => 'Scala',
        '.sh' => 'Shell Script',
        '.bash' => 'Bash',
        '.zsh' => 'Zsh',
        '.sql' => 'SQL',
        '.yml' => 'YAML',
        '.yaml' => 'YAML',
        '.json' => 'JSON',
        '.xml' => 'XML',
        '.dart' => 'Dart',
        '.vue' => 'Vue.js',
        '.svelte' => 'Svelte'
      }

      def initialize(file_path)
        @file_path = file_path
        @ai_provider = MitchAI::AIProviders::OpenAIProvider.new
      end

      def analyze
        # Read file contents
        code_content = File.read(@file_path)
        # Perform AI analysis
        ai_review = @ai_provider.analyze_code(code_content, language)

        # Construct result
        {
          file_path: @file_path,
          language: language,
          suggestions: parse_suggestions(ai_review[:suggestions])
        }
      rescue Errno::ENOENT => e
        # Wrap the low-level error in a more user-friendly message
        raise "Error reading file: #{e.message}"
        
      end

      private

      def extension
        File.extname(@file_path).downcase
      end

      def language
        LANGUAGE_MAP[extension] || 'Unknown'
      end

      def parse_suggestions(raw_suggestions)
        # Handle both string and array formats
        return raw_suggestions if raw_suggestions.is_a?(Array)
        
        # Otherwise parse the string as before
        raw_suggestions.to_s.split("\n").select do |suggestion| 
          suggestion.strip.length > 10 
        end
      end
    end
  end
end
