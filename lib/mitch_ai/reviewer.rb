# frozen_string_literal: true

require_relative 'mcp_client'
require_relative 'ollama_client'
require_relative 'language_detector'
require_relative 'smart_model_manager'
require 'json'
require 'colorize'

module MitchAI
  class Reviewer
    def initialize(options = {})
      @mcp_client = MCPClient.new
      @ollama_client = OllamaClient.new
      @model_manager = SmartModelManager.new
      @selected_model = options[:model]
      @verbose = options[:verbose] || false
    end

    def review_project(project_path)
      puts '🔍 Analyzing project structure...'.cyan

      # Step 1: Analyze project with MCP
      project_analysis = analyze_project_structure(project_path)

      # Step 2: Select optimal model
      @selected_model ||= select_and_prepare_model(project_analysis)

      # Step 3: Find and group files
      files_by_language = get_project_files(project_path, project_analysis[:languages_detected])

      # Step 4: Review files by language
      review_results = review_files_by_language(files_by_language)

      # Step 5: Present comprehensive results
      present_project_review(project_analysis, review_results)
    end

    def review_file(file_path)
      unless File.exist?(file_path)
        puts "❌ File not found: #{file_path}".red
        return nil
      end

      language = LanguageDetector.detect_language_from_extension(file_path)

      # Select model if not already set
      @selected_model ||= @model_manager.recommend_model_for_languages([language])
      @model_manager.ensure_model_ready(@selected_model)

      puts "📄 Reviewing #{File.basename(file_path)} (#{language})...".cyan

      # READ THE FILE DIRECTLY - don't use MCP for single files
      content = File.read(file_path, encoding: 'utf-8')

      result = review_single_file(file_path, content, language)

      if result
        present_single_file_review(file_path, result)
      else
        puts '❌ Failed to review file'.red
      end

      result
    end

    # Add this method to present single file results:
    private

    def present_single_file_review(file_path, result)
      puts "\n" + ('=' * 60)
      puts '🎉 MITCH-AI FILE REVIEW COMPLETE'.green.bold
      puts '=' * 60
      puts "File: #{file_path}"
      puts "Score: #{result[:score]}/10" if result[:score]

      if result[:issues]&.any?
        puts "\n🚨 ISSUES FOUND:".red.bold
        result[:issues].each_with_index do |issue, i|
          severity_color = case issue[:severity]
                           when 'critical' then :red
                           when 'major' then :yellow
                           else :white
                           end
          puts "#{i + 1}. #{issue[:description]}".send(severity_color)
          puts "   Fix: #{issue[:suggestion]}" if issue[:suggestion]
        end
      end

      if result[:suggestions]&.any?
        puts "\n💡 SUGGESTIONS:".blue.bold
        result[:suggestions].each_with_index do |suggestion, i|
          puts "#{i + 1}. #{suggestion[:description]}"
        end
      end

      if result[:priority_actions]&.any?
        puts "\n🎯 PRIORITY ACTIONS:".yellow.bold
        result[:priority_actions].each_with_index do |action, i|
          puts "#{i + 1}. #{action}"
        end
      end

      puts "\n✨ Review complete!".green
    end

    private

    def analyze_project_structure(project_path)
      puts '🔧 Running project analysis...'.yellow if @verbose

      analysis_result = @mcp_client.call_tool('analyze_project_structure', { path: project_path })
      analysis = JSON.parse(analysis_result, symbolize_names: true)

      puts "📋 Detected: #{analysis[:languages_detected].join(', ')}".yellow if @verbose
      puts "🎯 Project type: #{analysis[:project_type]}".yellow if @verbose

      analysis
    end

    def select_and_prepare_model(project_analysis)
      languages = project_analysis[:languages_detected]
      recommended_model = project_analysis[:recommended_model]

      puts "🧠 Selected model: #{recommended_model}".green

      model_info = @model_manager.get_model_info(recommended_model)
      puts "   Optimized for: #{model_info[:strengths].join(', ')}".green

      @model_manager.ensure_model_ready(recommended_model)
      recommended_model
    end

    def get_project_files(project_path, languages)
      puts '📁 Finding source files...'.cyan

      files_result = @mcp_client.call_tool('find_all_source_files', {
                                             path: project_path,
                                             languages: languages.map(&:to_s)
                                           })

      files_by_language = JSON.parse(files_result, symbolize_names: true)

      # Log file counts
      files_by_language.each do |language, files|
        next if files.empty?

        puts "   #{language}: #{files.length} files".white if @verbose
      end

      files_by_language
    end

    def review_files_by_language(files_by_language)
      results = {}
      total_files = files_by_language.values.flatten.length
      current_file = 0

      files_by_language.each do |language, files|
        next if files.empty?

        language_sym = language.to_sym
        puts "\n📋 Reviewing #{language} files (#{files.length} files)...".cyan

        results[language_sym] = {
          files: [],
          summary: {
            total_files: files.length,
            total_issues: 0,
            average_score: 0,
            language: language
          }
        }

        scores = []
        total_issues = 0

        files.each do |file_path|
          current_file += 1
          progress = (current_file.to_f / total_files * 100).round(1)

          print "\r   Progress: #{progress}% (#{File.basename(file_path)})".white

          begin
            content = File.read(file_path, encoding: 'utf-8')
            puts "📄 Reviewing #{File.basename(file_path)}..." if @verbose
            review_result = review_single_file(file_path, content, language_sym)

            if review_result
              results[language_sym][:files] << {
                path: file_path,
                result: review_result
              }

              scores << review_result[:score] if review_result[:score]
              total_issues += review_result[:issues]&.length || 0
            end
          rescue StandardError => e
            puts "\n⚠️  Error reviewing #{file_path}: #{e.message}".red if @verbose
          end
        end

        # Calculate summary statistics
        if scores.any?
          results[language_sym][:summary][:average_score] = (scores.sum.to_f / scores.length).round(1)
          results[language_sym][:summary][:total_issues] = total_issues
        end

        print "\r   #{language}: #{files.length} files reviewed ✅".green
        puts
      end

      results
    end

    def review_single_file(file_path, content, language)
      return nil if content.strip.empty?

      # Skip very large files (>10KB) to avoid token limits
      if content.bytesize > 10_240
        return {
          score: 5,
          issues: [{ description: "File too large for detailed review (#{content.bytesize} bytes)" }],
          summary: 'File skipped due to size'
        }
      end

      prompt = @model_manager.build_review_prompt(language, content, file_path)

      begin
        response = @ollama_client.chat(@selected_model, [
                                         { role: 'user', content: prompt }
                                       ])

        # Handle different response types
        response_text = if response.is_a?(Hash)
                          # If ollama_client returns a hash, extract the message content
                          response.dig('message', 'content') || response.dig(:message, :content) || response.to_s
                        else
                          # If it's a string, use it directly
                          response.to_s
                        end

        # Parse JSON response
        if response_text && response_text.include?('{')
          json_start = response_text.index('{')
          json_end = response_text.rindex('}') + 1
          json_content = response_text[json_start...json_end]

          JSON.parse(json_content, symbolize_names: true)
        else
          # Fallback for non-JSON responses
          {
            score: 6,
            issues: [],
            summary: response_text&.strip || 'Review completed',
            raw_response: response
          }
        end
      rescue JSON::ParserError => e
        puts "\n⚠️  JSON parsing error for #{file_path}: #{e.message}".red if @verbose
        {
          score: 5,
          issues: [{ description: 'Could not parse AI response' }],
          summary: 'Review parsing failed',
          raw_response: response
        }
      rescue StandardError => e
        puts "\n❌ Error reviewing #{file_path}: #{e.message}".red if @verbose
        nil
      end
    end

    def present_project_review(project_analysis, review_results)
      puts "\n" + ('=' * 60)
      puts '🎉 MITCH-AI PROJECT REVIEW COMPLETE'.green.bold
      puts '=' * 60

      # Project overview
      puts "\n📊 PROJECT OVERVIEW".blue.bold
      puts "Languages: #{project_analysis[:languages_detected].join(', ')}"
      puts "Project Type: #{project_analysis[:project_type]}"
      puts "Model Used: #{@selected_model}"

      # Language summaries
      puts "\n📋 LANGUAGE BREAKDOWN".blue.bold
      review_results.each do |language, data|
        summary = data[:summary]
        puts "\n#{language.to_s.upcase}:"
        puts "   Files: #{summary[:total_files]}"
        puts "   Average Score: #{summary[:average_score]}/10"
        puts "   Total Issues: #{summary[:total_issues]}"

        # Show worst files
        worst_files = data[:files]
                      .select { |f| f[:result][:score] }
                      .sort_by { |f| f[:result][:score] }
                      .first(3)

        next unless worst_files.any?

        puts '   Needs Attention:'
        worst_files.each do |file_data|
          score = file_data[:result][:score]
          filename = File.basename(file_data[:path])
          puts "     #{filename} (#{score}/10)".yellow
        end
      end

      # Overall recommendations
      puts "\n🎯 TOP RECOMMENDATIONS".blue.bold
      all_priority_actions = extract_priority_actions(review_results)

      if all_priority_actions.any?
        all_priority_actions.first(5).each_with_index do |action, i|
          puts "#{i + 1}. #{action}".yellow
        end
      else
        puts 'Great job! No major issues found.'.green
      end

      # Files needing immediate attention
      critical_files = find_critical_files(review_results)
      if critical_files.any?
        puts "\n🚨 CRITICAL ISSUES".red.bold
        critical_files.each do |file_info|
          puts "#{file_info[:path]}:".red
          file_info[:issues].each do |issue|
            puts "   • #{issue[:description]}".white
          end
        end
      end

      puts "\n✨ Review complete! Focus on the critical issues first.".green
    end

    def extract_priority_actions(review_results)
      actions = []

      review_results.each do |_, data|
        data[:files].each do |file_data|
          result = file_data[:result]
          actions.concat(result[:priority_actions]) if result[:priority_actions]&.any?
        end
      end

      # Remove duplicates and return most common
      action_counts = actions.group_by(&:itself).transform_values(&:count)
      action_counts.sort_by { |_, count| -count }.map { |action, _| action }
    end

    def find_critical_files(review_results)
      critical = []

      review_results.each do |_, data|
        data[:files].each do |file_data|
          result = file_data[:result]

          # Files with score < 5 or critical issues
          next unless (result[:score] && result[:score] < 5) ||
                      result[:issues]&.any? { |issue| issue[:severity] == 'critical' }

          critical_issues = result[:issues]&.select do |issue|
            issue[:severity] == 'critical' || result[:score] < 5
          end || []

          next unless critical_issues.any?

          critical << {
            path: file_data[:path],
            score: result[:score],
            issues: critical_issues
          }
        end
      end

      critical.sort_by { |f| f[:score] || 0 }
    end
  end
end
