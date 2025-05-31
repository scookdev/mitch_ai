# frozen_string_literal: true

require_relative 'reviewer'
require_relative 'language_detector'
require_relative 'smart_model_manager'
require_relative 'ollama_manager'

module MitchAI
  class CLI
    def self.start(args)
      command = args[0]

      case command
      when 'review'
        review_command(args[1..-1])
      when 'setup'
        setup_command(args[1..-1])
      when 'languages'
        list_languages_command
      when 'models'
        list_models_command
      when 'version', '-v', '--version'
        version_command
      when 'help', '-h', '--help', nil
        show_help
      else
        puts "❌ Unknown command: #{command}"
        puts 'Try: mitch-ai help'
        exit 1
      end
    rescue StandardError => e
      puts "💥 Error: #{e.message}".red
      puts 'Try: mitch-ai help' unless args.include?('-v')
      exit 1
    end

    def self.review_command(args)
      path = args.first || '.'
      verbose = args.include?('-v') || args.include?('--verbose')

      unless File.exist?(path)
        puts "❌ Path not found: #{path}".red
        exit 1
      end

      puts '🔍 Starting Mitch-AI review...'.cyan
      puts "📁 Target: #{File.expand_path(path)}".white if verbose

      # Check prerequisites
      check_prerequisites(verbose)

      # Create reviewer
      reviewer = Reviewer.new(verbose: verbose)

      if File.file?(path)
        # Single file review
        puts '📄 Reviewing single file...'.cyan
        reviewer.review_file(path)
      else
        # Project review
        puts '📦 Reviewing entire project...'.cyan
        reviewer.review_project(path)
      end
    rescue StandardError => e
      puts "💥 Review failed: #{e.message}".red
      puts 'Use -v for more details' unless verbose
      puts e.backtrace.join("\n") if verbose
      exit 1
    end

    def self.setup_command(_args)
      puts '🚀 Setting up Mitch-AI...'.cyan

      begin
        # Check if Ollama is installed
        unless system('ollama --version > /dev/null 2>&1')
          puts '❌ Ollama not found. Please install Ollama first:'.red
          puts '   Visit: https://ollama.ai/'
          exit 1
        end

        puts '✅ Ollama found'.green

        # Detect current project (if in a project directory)
        if Dir.exist?('.')
          detector = LanguageDetector.new('.')
          languages = detector.detect_languages

          if languages.any? && languages != [:ruby] # More than just default
            puts "🔍 Detected languages in current directory: #{languages.join(', ')}".yellow

            # Recommend model
            model_manager = SmartModelManager.new
            recommended_model = model_manager.recommend_model_for_languages(languages)

            puts "🧠 Recommended model: #{recommended_model}".green

            print "Download #{recommended_model}? (Y/n): "
            choice = gets.chomp.downcase

            if choice.empty? || choice == 'y' || choice == 'yes'
              model_manager.ensure_model_ready(recommended_model)
              puts '🎉 Setup complete! Try: mitch-ai review'.green
            else
              puts '⏭️  Skipped model download. You can run setup again later.'.yellow
            end
          else
            puts '📝 No specific project detected. Default model will be selected during review.'.white
          end
        end

        puts "\n✨ Mitch-AI is ready! Try these commands:".green
        puts '   mitch-ai review          # Review current directory'
        puts '   mitch-ai review ./file   # Review specific file'
        puts '   mitch-ai languages       # See supported languages'
      rescue StandardError => e
        puts "💥 Setup failed: #{e.message}".red
        exit 1
      end
    end

    def self.list_languages_command
      puts '🌐 Supported Languages:'.cyan

      languages = {
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
      }

      languages.each do |language, patterns|
        puts "  #{language.ljust(12)} #{patterns.join(', ')}".white
      end

      puts "\n💡 More languages coming soon!".yellow
    end

    def self.list_models_command
      puts '🤖 Available Models:'.cyan

      begin
        ollama_manager = OllamaManager.new
        models = ollama_manager.available_models

        if models.empty?
          puts '  No models installed yet.'.yellow
          puts "  Run 'mitch-ai setup' to install recommended models.".white
        else
          models.each do |model|
            puts "  ✅ #{model}".green
          end
        end

        puts "\n🧠 Recommended Models:".cyan
        SmartModelManager.new
        SmartModelManager::MODEL_CAPABILITIES.each do |model, info|
          status = models.include?(model) ? '✅' : '⬇️ '
          puts "  #{status} #{model.ljust(20)} #{info[:description]}".white
          puts "     Strengths: #{info[:strengths].join(', ')}".white
          puts "     Size: #{info[:size]}".white
          puts
        end
      rescue StandardError => e
        puts "❌ Could not check models: #{e.message}".red
      end
    end

    def self.version_command
      puts 'Mitch-AI v1.0.0'
      puts 'Local AI Code Review Platform'
      puts 'Built with ❤️ for developers'
    end

    def self.show_help
      puts <<~HELP
        #{'Mitch-AI - Local AI Code Review Platform'.cyan}

        #{'USAGE:'.yellow}
          mitch-ai <command> [options]

        #{'COMMANDS:'.yellow}
          #{'review [path]'.green}      Review file or project (default: current directory)
          #{'setup'.green}             Set up Mitch-AI and download models
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

    def self.check_prerequisites(verbose = false)
      puts '🔧 Checking prerequisites...'.yellow if verbose

      # Check Ollama
      unless system('ollama --version > /dev/null 2>&1')
        puts '❌ Ollama not found. Install from: https://ollama.ai/'.red
        exit 1
      end

      puts '✅ Ollama available'.green if verbose

      # Check if Ollama is running
      unless system('ollama list > /dev/null 2>&1')
        puts '❌ Ollama service not running. Start with: ollama serve'.red
        exit 1
      end

      puts '✅ Ollama service running'.green if verbose
    end
  end
end

# Add colorize support if available
begin
  require 'colorize'
rescue LoadError
  # Define color methods as no-ops if colorize isn't available
  class String
    %i[red green yellow blue cyan white].each do |color|
      define_method(color) { self }
    end
  end
end
