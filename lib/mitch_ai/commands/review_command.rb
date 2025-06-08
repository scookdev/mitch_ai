# frozen_string_literal: true

require_relative 'base_command'
require_relative '../reviewer'

module MitchAI
  module Commands
    class ReviewCommand < BaseCommand
      def call(args)
        path = args.first || '.'
        verbose = verbose_mode?(args)

        validate_path(path)
        start_review_process(path, verbose: verbose)
      rescue StandardError => e
        handle_review_error(e, verbose)
      end

      private

      def start_review_process(path, verbose:)
        puts '🔍 Starting Mitch-AI review...'.cyan
        puts "📁 Target: #{File.expand_path(path)}".white if verbose

        check_prerequisites(verbose: verbose)
        reviewer = Reviewer.new(verbose: verbose)
        perform_review(reviewer, path)
      end

      def perform_review(reviewer, path)
        if File.file?(path)
          puts '📄 Reviewing single file...'.cyan
          reviewer.review_file(path)
        else
          puts '📦 Reviewing entire project...'.cyan
          reviewer.review_project(path)
        end
      end

      def handle_review_error(error, verbose)
        puts "💥 Review failed: #{error.message}".red
        puts 'Use -v for more details' unless verbose
        puts error.backtrace.join("\n") if verbose
        exit 1
      end
    end
  end
end