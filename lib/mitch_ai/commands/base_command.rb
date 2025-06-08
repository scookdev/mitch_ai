# frozen_string_literal: true

module MitchAI
  module Commands
    class BaseCommand
      def self.call(*)
        new.call(*)
      end

      protected

      def verbose_mode?(args)
        args.include?('-v') || args.include?('--verbose')
      end

      def validate_path(path)
        return if File.exist?(path)

        puts "❌ Path not found: #{path}".red
        exit 1
      end

      def check_prerequisites(verbose: false)
        puts '🔧 Checking prerequisites...'.yellow if verbose

        check_ollama_available(verbose)
        check_ollama_running(verbose)
      end

      private

      def check_ollama_available(verbose)
        unless system('ollama --version > /dev/null 2>&1')
          puts '❌ Ollama not found. Install from: https://ollama.ai/'.red
          exit 1
        end

        puts '✅ Ollama available'.green if verbose
      end

      def check_ollama_running(verbose)
        unless system('ollama list > /dev/null 2>&1')
          puts '❌ Ollama service not running. Start with: ollama serve'.red
          exit 1
        end

        puts '✅ Ollama service running'.green if verbose
      end
    end
  end
end