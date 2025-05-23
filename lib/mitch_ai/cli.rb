# frozen_string_literal: true

require 'thor'
require 'json'
require 'tty-spinner'
require_relative 'configuration'
require_relative 'analyzers/file_analyzer'

module MitchAI
  class CLI < Thor
    desc 'review PATH', 'Analyze code at the specified path'
    option :format, default: 'terminal', desc: 'Output format (terminal, json)'
    option :provider, default: 'openai', desc: 'AI provider to use'
    option :verbose, type: :boolean, default: false, desc: 'Show verbose output'

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def review(path)
      # Validate API key is configured
      ensure_api_key_configured

      # Determine if path is file or directory
      paths = if File.directory?(path)
                Dir.glob("#{path}/**/*").select { |f| File.file?(f) }
              else
                [path]
              end

      results = paths.map do |file_path|
        spinner = TTY::Spinner.new("[:spinner] Analyzing #{file_path}...", format: :dots)
        spinner.auto_spin

        analyzer = Analyzers::FileAnalyzer.new(file_path)
        result = analyzer.analyze
        spinner.success('✅ Done')
        result
      rescue StandardError => e
        puts "❌ Error: #{e.message}"
        nil
      end.compact
      puts "\nFound #{results.length} files to analyze\n\n"

      # Output results
      output_results(results, options[:format])
    rescue StandardError => e
      # Stop the spinner with error message if there's an exception
      spinner.error('(Error!)') if defined?(spinner) && spinner
      puts "Error during analysis: #{e.class}: #{e.message}"
      puts e.backtrace[0..5] if options[:verbose]
      nil
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def ensure_api_key_configured
      config = Configuration.new
      return unless config.api_key.nil?

      puts '❌ No API key configured. Please run:'
      puts '   mitch-ai configure'
      exit 1 unless ENV['RSPEC_RUNNING']
    end

    def output_results(results, format)
      case format
      when 'terminal'
        print_terminal_results(results)
      when 'json'
        puts JSON.pretty_generate(results)
      else
        raise "Unsupported format: #{format}"
      end
    end

    def print_terminal_results(results)
      results.each do |result|
        puts "🔍 File: #{result[:file_path]}"
        puts "Language: #{result[:language]}"
        puts 'Suggestions:'
        result[:suggestions].each do |suggestion|
          puts "- #{suggestion}"
        end
        puts "\n"
      end
    end
  end
end
