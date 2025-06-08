# frozen_string_literal: true

require_relative 'base_command'
require_relative '../language_detector'
require_relative '../smart_model_manager'

module MitchAI
  module Commands
    class SetupCommand < BaseCommand
      def call(_args)
        puts '🚀 Setting up Mitch-AI...'.cyan

        begin
          check_ollama_installation
          detect_and_setup_project
          show_setup_completion_message
        rescue StandardError => e
          puts "💥 Setup failed: #{e.message}".red
          exit 1
        end
      end

      private

      def check_ollama_installation
        unless system('ollama --version > /dev/null 2>&1')
          puts '❌ Ollama not found. Please install Ollama first:'.red
          puts '   Visit: https://ollama.ai/'
          exit 1
        end

        puts '✅ Ollama found'.green
      end

      def detect_and_setup_project
        return unless Dir.exist?('.')

        detector = LanguageDetector.new('.')
        languages = detector.detect_languages

        if languages.any? && languages != [:ruby]
          setup_project_with_languages(languages)
        else
          puts '📝 No specific project detected. Default model will be selected during review.'.white
        end
      end

      def setup_project_with_languages(languages)
        puts "🔍 Detected languages in current directory: #{languages.join(', ')}".yellow

        model_manager = SmartModelManager.new
        
        # Show tier selection
        puts "\n🎯 Choose your performance tier:".cyan
        puts "  1) 🚀 Fast (1.6-2.2GB) - Quick setup, good quality reviews"
        puts "  2) ⚖️  Balanced (3.8-4.1GB) - Better quality, moderate setup"
        puts "  3) 🎯 Premium (7-19GB) - Best quality, longer setup"
        puts
        
        print "What's your preference? [1/2/3] (default: 1): "
        choice = gets&.chomp || '1'
        
        tier = case choice
               when '2' then :balanced
               when '3' then :premium
               else :fast
               end
        
        recommended_model = model_manager.recommend_model_for_languages(languages, tier: tier)
        model_info = model_manager.get_model_info(recommended_model)
        
        puts "\n🧠 Selected model: #{recommended_model}".green
        puts "   Size: #{model_info[:size]}, Quality: #{model_info[:quality_score]}/10"
        puts "   #{model_info[:description]}"

        success = model_manager.ensure_model_ready(recommended_model, languages: languages, interactive: true)
        
        if success
          puts '🎉 Setup complete! Try: mitch-ai review'.green
        else
          puts '⏭️  Setup incomplete. You can run setup again later.'.yellow
        end
      end

      def prompt_for_model_download(model)
        print "Download #{model}? (Y/n): "
        choice = gets.chomp.downcase
        choice.empty? || choice == 'y' || choice == 'yes'
      end

      def show_setup_completion_message
        # Start MCP server if not running
        unless server_running?
          puts "\n🚀 Starting MCP server for enhanced features...".cyan
          start_mcp_server
        end

        puts "\n✨ Mitch-AI is ready! Try these commands:".green
        puts '   mitch-ai review          # Review current directory'
        puts '   mitch-ai review ./file   # Review specific file'
        puts '   mitch-ai server status   # Check MCP server status'
        puts '   mitch-ai languages       # See supported languages'
      end

      def server_running?(port = 4568)
        system("curl -s http://localhost:#{port}/status > /dev/null 2>&1")
      end

      def start_mcp_server(port = 4568)
        require_relative '../commands/server_command'
        Commands::ServerCommand.new.call(['start', "--port=#{port}"])
      end
    end
  end
end