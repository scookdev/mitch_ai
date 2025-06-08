# frozen_string_literal: true

require_relative 'base_command'
require_relative '../smart_model_manager'
require_relative '../language_detector'

module MitchAI
  module Commands
    class ModelsCommand < BaseCommand
      def call(args)
        action = args.first || 'list'

        case action
        when 'list'
          list_models
        when 'upgrade'
          upgrade_models(args[1..])
        when 'tiers'
          show_tiers
        when 'install'
          install_model(args[1..])
        when 'remove'
          remove_model(args[1..])
        else
          puts "❌ Unknown models action: #{action}".red
          show_models_help
        end
      end

      private

      def list_models
        models_data = EnhancedSpinner.thinking('Analyzing model ecosystem') do
          model_manager = SmartModelManager.new
          available_models = model_manager.instance_variable_get(:@ollama_manager).available_models
          { model_manager: model_manager, available_models: available_models }
        end
        
        model_manager = models_data[:model_manager]
        available_models = models_data[:available_models]
        
        puts '🤖 Model Status:'.cyan
        puts
        
        # Group by tier
        SmartModelManager::MODEL_TIERS.each do |tier, tier_info|
          tier_models = SmartModelManager::MODEL_CAPABILITIES.select { |_, info| info[:tier] == tier }
          
          puts "#{tier_emoji(tier)} #{tier.to_s.capitalize} Tier (#{tier_info[:description]})".send(tier_color(tier))
          
          tier_models.each do |model, info|
            status = available_models.include?(model) ? '✅' : '⬇️ '
            quality = '★' * info[:quality_score] + '☆' * (10 - info[:quality_score])
            
            puts "  #{status} #{model.ljust(20)} #{info[:size].ljust(6)} #{quality}"
            puts "     #{info[:description]}".white
            puts "     Languages: #{info[:strengths].join(', ')}".white
            puts
          end
        end

        # Show upgrade suggestions if we detect languages
        if Dir.exist?('.')
          detector = LanguageDetector.new('.')
          languages = detector.detect_languages
          
          if languages.any? && available_models.any?
            show_upgrade_suggestions(languages, available_models, model_manager)
          end
        end
      end

      def upgrade_models(args)
        model_manager = SmartModelManager.new
        available_models = model_manager.instance_variable_get(:@ollama_manager).available_models
        
        # Detect current project languages
        languages = []
        if Dir.exist?('.')
          detector = LanguageDetector.new('.')
          languages = detector.detect_languages
          puts "🔍 Detected languages: #{languages.join(', ')}".yellow
        end

        if languages.empty?
          puts "❌ No project languages detected. Run from a project directory or specify languages."
          return
        end

        # Find current model (assume we're using the best available)
        current_model = find_current_model(languages, available_models, model_manager)
        
        unless current_model
          puts "❌ No compatible models installed. Run 'mitch-ai setup' first."
          return
        end

        puts "📋 Current model: #{current_model}".white
        
        # Get upgrade suggestions
        upgrades = model_manager.get_upgrade_suggestions(current_model, languages)
        
        if upgrades.empty?
          puts "✅ You're already using the best available model for your languages!".green
          return
        end

        puts "\n⬆️  Available upgrades:".cyan
        upgrades.first(3).each_with_index do |upgrade, i|
          info = upgrade[:info]
          improvement = upgrade[:quality_improvement]
          puts "  #{i + 1}) #{upgrade[:model]} (+#{improvement} quality)"
          puts "     #{info[:description]} (#{info[:size]})"
          puts "     Setup time: #{SmartModelManager::MODEL_TIERS[upgrade[:tier]][:setup_time]}"
          puts
        end

        print "Choose upgrade [1-#{upgrades.length}/cancel]: "
        choice = gets&.chomp || 'cancel'
        
        upgrade_index = choice.to_i - 1
        if upgrade_index >= 0 && upgrade_index < upgrades.length
          selected_upgrade = upgrades[upgrade_index]
          puts "\n🚀 Upgrading to #{selected_upgrade[:model]}...".cyan
          
          success = model_manager.ensure_model_ready(
            selected_upgrade[:model], 
            languages: languages, 
            interactive: true
          )
          
          if success
            puts "🎉 Upgrade complete! #{selected_upgrade[:quality_improvement]} points better quality.".green
            puts "💡 Use 'mitch-ai review' to see the improved analysis."
          end
        else
          puts "❌ Upgrade cancelled"
        end
      end

      def show_tiers
        puts '🎯 Model Tiers:'.cyan
        puts
        
        SmartModelManager::MODEL_TIERS.each do |tier, info|
          models = SmartModelManager::MODEL_CAPABILITIES.select { |_, model_info| model_info[:tier] == tier }
          
          puts "#{tier_emoji(tier)} #{tier.to_s.capitalize} Tier".send(tier_color(tier))
          puts "   #{info[:description]}"
          puts "   Setup time: #{info[:setup_time]}"
          puts "   Models: #{models.keys.join(', ')}"
          puts
        end
        
        puts "💡 Use 'mitch-ai setup' to choose your tier, or 'mitch-ai models upgrade' to upgrade later."
      end

      def install_model(args)
        model_name = args.first
        unless model_name
          puts "❌ Please specify a model name"
          puts "   Example: mitch-ai models install codegemma:2b"
          return
        end

        model_manager = SmartModelManager.new
        model_manager.ensure_model_ready(model_name, interactive: true)
      end

      def remove_model(args)
        model_name = args.first
        unless model_name
          puts "❌ Please specify a model name"
          return
        end

        print "Remove #{model_name}? This will free up disk space. [y/N]: "
        choice = gets.chomp.downcase
        
        if choice == 'y' || choice == 'yes'
          puts "🗑️  Removing #{model_name}...".yellow
          system("ollama rm #{model_name}")
          puts "✅ Model removed"
        end
      end

      def show_upgrade_suggestions(languages, available_models, model_manager)
        current_model = find_current_model(languages, available_models, model_manager)
        return unless current_model

        upgrades = model_manager.get_upgrade_suggestions(current_model, languages)
        return if upgrades.empty?

        best_upgrade = upgrades.first
        puts "💡 Upgrade available:".yellow
        puts "   #{best_upgrade[:model]} (+#{best_upgrade[:quality_improvement]} quality)"
        puts "   Run: mitch-ai models upgrade"
        puts
      end

      def find_current_model(languages, available_models, model_manager)
        # Find the best available model for current languages
        best_available = nil
        best_score = 0

        available_models.each do |model|
          info = SmartModelManager::MODEL_CAPABILITIES[model]
          next unless info

          compatibility = model_manager.send(:calculate_language_compatibility, info[:strengths], languages)
          score = compatibility * info[:quality_score]
          
          if score > best_score
            best_score = score
            best_available = model
          end
        end

        best_available
      end

      def tier_emoji(tier)
        case tier
        when :fast then '🚀'
        when :balanced then '⚖️'
        when :premium then '🎯'
        end
      end

      def tier_color(tier)
        case tier
        when :fast then :cyan
        when :balanced then :yellow
        when :premium then :magenta
        end
      end

      def show_models_help
        puts <<~HELP
          #{'Model Management'.cyan}

          #{'USAGE:'.yellow}
            mitch-ai models <action> [options]

          #{'ACTIONS:'.yellow}
            #{'list'.green}          List all models with status and tiers
            #{'upgrade'.green}       Upgrade to better models for current project
            #{'tiers'.green}         Show available model tiers
            #{'install <model>'.green}   Install a specific model
            #{'remove <model>'.green}    Remove a model to free disk space

          #{'EXAMPLES:'.yellow}
            mitch-ai models list
            mitch-ai models upgrade
            mitch-ai models tiers
            mitch-ai models install codegemma:2b
            mitch-ai models remove deepseek-coder:6.7b
        HELP
      end
    end
  end
end