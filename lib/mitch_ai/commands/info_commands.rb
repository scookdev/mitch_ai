# frozen_string_literal: true

require_relative 'base_command'
require_relative '../ollama_manager'
require_relative '../smart_model_manager'

module MitchAI
  module Commands
    class LanguagesCommand < BaseCommand
      SUPPORTED_LANGUAGES = {
        'Ruby' => ['.rb', '.rake', 'Gemfile', 'Rakefile'],
        'Python' => ['.py', '.pyw', 'requirements.txt', 'setup.py'],
        'TypeScript' => ['.ts', '.tsx', 'tsconfig.json'],
        'JavaScript' => ['.js', '.jsx', 'package.json'],
        'Go' => ['.go', 'go.mod', 'go.sum'],
        'Rust' => ['.rs', 'Cargo.toml'],
        'CSS' => ['.css', '.scss', '.sass'],
        'Java' => ['.java', 'pom.xml', 'build.gradle'],
        'C++' => ['.cpp', '.cc', '.h', '.hpp'],
        'HTML' => ['.html', '.htm']
      }.freeze

      def call(_args)
        puts '🌐 Supported Languages:'.cyan

        SUPPORTED_LANGUAGES.each do |language, patterns|
          puts "  #{language.ljust(12)} #{patterns.join(', ')}".white
        end

        puts "\n💡 More languages coming soon!".yellow
      end
    end


    class VersionCommand < BaseCommand
      def call(_args)
        puts 'Mitch-AI v1.0.0'
        puts 'Local AI Code Review Platform'
        puts 'Built with ❤️ for developers'
      end
    end

    class HelpCommand < BaseCommand
      def call(_args)
        puts help_content
      end

      private

      def help_content
        <<~HELP
          #{'Mitch-AI - Local AI Code Review Platform'.cyan}

          #{'USAGE:'.yellow}
            mitch-ai <command> [options]

          #{'COMMANDS:'.yellow}
            #{'review [path]'.green}      Review file or project (default: current directory)
            #{'setup'.green}             Set up Mitch-AI and download models
            #{'server'.green}            Start/stop/manage MCP server
            #{'languages'.green}         List supported programming languages
            #{'models'.green}            List available and recommended models
            #{'version'.green}           Show version information
            #{'help'.green}              Show this help message

          #{'OPTIONS:'.yellow}
            #{'-v, --verbose'.green}      Enable verbose output
            #{'-h, --help'.green}        Show help

          #{'EXAMPLES:'.yellow}
            mitch-ai setup
            mitch-ai review
            mitch-ai review ./app/models/user.rb
            mitch-ai review ./my-project -v
            mitch-ai languages
          #{'  '}
          #{'GETTING STARTED:'.yellow}
            1. Run 'mitch-ai setup' to install required models
            2. Run 'mitch-ai review' to analyze your code
            3. Follow the recommendations to improve your code!
          #{'  '}
          For more info: https://github.com/your-username/mitch-ai
        HELP
      end
    end
  end
end