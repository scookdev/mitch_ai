# frozen_string_literal: true

require_relative 'ollama_manager'
require_relative 'language_detector'

module MitchAI
  class SmartModelManager
    LANGUAGE_PROMPTS = {
      ruby: <<~PROMPT,
        You are an expert Ruby code reviewer with deep knowledge of Ruby idioms and Rails conventions. Focus on:

        **Ruby Best Practices:**
        - Idiomatic Ruby patterns and conventions
        - Proper use of blocks, procs, and lambdas
        - Method visibility and encapsulation
        - Performance optimizations (avoid N+1 queries, etc.)

        **Rails Conventions (if applicable):**
        - MVC architecture adherence
        - RESTful design patterns
        - Strong parameters and security
        - Database query optimization

        **Code Quality:**
        - DRY (Don't Repeat Yourself) principle
        - SOLID principles application
        - Proper error handling and exceptions
        - Test coverage and testability

        **Security Concerns:**
        - SQL injection prevention
        - XSS protection
        - Authentication and authorization
        - Input validation and sanitization
      PROMPT

      python: <<~PROMPT,
        You are an expert Python code reviewer with extensive knowledge of Pythonic patterns and modern Python practices. Focus on:

        **Python Best Practices:**
        - PEP 8 style guidelines compliance
        - Pythonic idioms and patterns
        - Proper use of data structures and algorithms
        - Type hints and documentation (docstrings)

        **Code Organization:**
        - Function and class design
        - Module structure and imports
        - Exception handling best practices
        - Context managers and resource management

        **Performance & Security:**
        - Memory usage and performance considerations
        - Security vulnerabilities (injection attacks, etc.)
        - Async/await patterns (if applicable)
        - Testing patterns and coverage

        **Framework-Specific (when detected):**
        - Django: Models, views, templates, security
        - Flask: Route design, blueprints, extensions
        - FastAPI: Type annotations, async patterns
      PROMPT

      typescript: <<~PROMPT,
        You are an expert TypeScript code reviewer with deep knowledge of modern TypeScript, React, and frontend best practices. Focus on:

        **TypeScript Excellence:**
        - Type safety and strict mode compliance
        - Proper interface and type definitions
        - Generic usage and constraint handling
        - Advanced TypeScript features (mapped types, conditional types)

        **React Best Practices (if applicable):**
        - Component design and composition
        - Hook usage and custom hooks
        - State management patterns
        - Performance optimization (useMemo, useCallback, React.memo)

        **Modern JavaScript/ES6+:**
        - Async/await patterns
        - Module system and imports
        - Destructuring and spread operators
        - Arrow functions and proper scope handling

        **Frontend Architecture:**
        - Component reusability and maintainability
        - Error boundaries and error handling
        - Accessibility (a11y) considerations
        - Bundle size and performance impact
      PROMPT

      javascript: <<~PROMPT,
        You are an expert JavaScript code reviewer with comprehensive knowledge of modern JavaScript, Node.js, and web development. Focus on:

        **Modern JavaScript:**
        - ES6+ features and proper usage
        - Async/await vs Promises patterns
        - Module system (ESM/CommonJS)
        - Proper scoping and closure usage

        **Code Quality:**
        - Function design and pure functions
        - Error handling and debugging
        - Memory leaks and performance
        - Browser compatibility considerations

        **Node.js (if backend):**
        - Express.js patterns and middleware
        - Database integration best practices
        - Security considerations (helmet, validation)
        - API design and RESTful patterns

        **Frontend (if applicable):**
        - DOM manipulation best practices
        - Event handling and delegation
        - Performance optimization
        - Cross-browser compatibility
      PROMPT

      go: <<~PROMPT,
        You are an expert Go code reviewer with deep understanding of Go idioms, concurrency patterns, and systems programming. Focus on:

        **Go Idioms:**
        - Proper error handling patterns
        - Interface design and implementation
        - Struct composition vs inheritance
        - Package organization and naming

        **Concurrency:**
        - Goroutine usage and lifecycle
        - Channel patterns and select statements
        - Mutex and sync package usage
        - Race condition prevention

        **Performance & Memory:**
        - Memory allocation patterns
        - Garbage collection considerations
        - Profiling opportunities
        - Efficient data structures

        **Systems Programming:**
        - I/O handling and buffering
        - Network programming patterns
        - Context usage for cancellation
        - Testing strategies and benchmarks
      PROMPT

      rust: <<~PROMPT,
        You are an expert Rust code reviewer with comprehensive knowledge of Rust's ownership system, memory safety, and systems programming. Focus on:

        **Ownership & Borrowing:**
        - Proper ownership transfer patterns
        - Borrowing rules and lifetime management
        - Reference vs owned data decisions
        - Smart pointer usage (Box, Rc, Arc)

        **Memory Safety:**
        - Avoiding unsafe code when possible
        - Proper unsafe block justification
        - Memory leak prevention
        - Thread safety patterns

        **Rust Idioms:**
        - Error handling with Result and Option
        - Pattern matching best practices
        - Trait design and implementation
        - Macro usage and design

        **Performance:**
        - Zero-cost abstractions
        - Compiler optimization opportunities
        - Async/await patterns (if applicable)
        - Benchmarking and profiling
      PROMPT

      css: <<~PROMPT,
        You are an expert CSS code reviewer with deep knowledge of modern CSS, design systems, and web performance. Focus on:

        **Modern CSS:**
        - CSS Grid and Flexbox usage
        - Custom properties (CSS variables)
        - Modern pseudo-selectors and functions
        - CSS logical properties for internationalization

        **Performance:**
        - Selector efficiency and specificity
        - Critical CSS and loading strategies
        - Animation performance (transform/opacity)
        - Font loading and display strategies

        **Maintainability:**
        - CSS architecture (BEM, utility-first, etc.)
        - Component-based styling
        - Consistent naming conventions
        - Responsive design patterns

        **Accessibility & UX:**
        - Color contrast and accessibility
        - Focus management and keyboard navigation
        - Reduced motion preferences
        - Screen reader compatibility
      PROMPT

      java: <<~PROMPT,
        You are an expert Java code reviewer with extensive knowledge of Java best practices, enterprise patterns, and modern Java features. Focus on:

        **Java Best Practices:**
        - Object-oriented design principles
        - Proper exception handling
        - Collection framework usage
        - Stream API and functional programming

        **Enterprise Patterns:**
        - Spring Framework conventions (if applicable)
        - Dependency injection patterns
        - Transaction management
        - Security best practices

        **Performance & Memory:**
        - Garbage collection considerations
        - Memory leak prevention
        - Thread safety and concurrency
        - JVM optimization opportunities

        **Modern Java Features:**
        - Lambda expressions and method references
        - Optional usage patterns
        - Module system (if applicable)
        - Records and sealed classes
      PROMPT

      generic: <<~PROMPT
        You are an expert code reviewer with broad knowledge across multiple programming languages. Analyze this code for:

        **General Code Quality:**
        - Readability and maintainability
        - Consistent naming conventions
        - Proper code organization
        - Comment quality and documentation

        **Best Practices:**
        - Error handling patterns
        - Performance considerations
        - Security vulnerabilities
        - Testing strategies

        **Architecture:**
        - Design patterns usage
        - Separation of concerns
        - Code reusability
        - Scalability considerations
      PROMPT
    }.freeze

    MODEL_TIERS = {
      fast: {
        priority: 1,
        description: 'Fast downloads, good quality',
        setup_time: '~2 minutes'
      },
      balanced: {
        priority: 2,
        description: 'Better quality, moderate setup',
        setup_time: '~5-10 minutes'
      },
      premium: {
        priority: 3,
        description: 'Best quality, longer setup',
        setup_time: '~10-15 minutes'
      }
    }.freeze

    MODEL_CAPABILITIES = {
      # Fast Tier - Quick downloads for immediate functionality
      'codegemma:2b' => {
        strengths: %i[ruby python typescript javascript css html go java],
        description: 'Fast, lightweight model for quick reviews',
        size: '1.6GB',
        tier: :fast,
        quality_score: 7
      },
      'phi3:mini' => {
        strengths: %i[python javascript typescript],
        description: 'Microsoft\'s efficient coding model',
        size: '2.2GB',
        tier: :fast,
        quality_score: 7
      },
      
      # Balanced Tier - Current models
      'deepseek-coder:6.7b' => {
        strengths: %i[ruby python typescript javascript css html],
        description: 'Excellent general-purpose coding model, best for web development',
        size: '3.8GB',
        tier: :balanced,
        quality_score: 9
      },
      'qwen2.5-coder:7b' => {
        strengths: %i[rust go cpp java],
        description: 'Optimized for systems programming and compiled languages',
        size: '4.1GB',
        tier: :balanced,
        quality_score: 9
      },
      'codellama:7b' => {
        strengths: %i[python java cpp ruby],
        description: 'Strong for enterprise languages and complex logic',
        size: '3.9GB',
        tier: :balanced,
        quality_score: 8
      },
      
      # Premium Tier - High quality, large downloads
      'codellama:13b' => {
        strengths: %i[python java cpp rust go],
        description: 'Most capable model with superior code understanding',
        size: '7.3GB',
        tier: :premium,
        quality_score: 10
      },
      'deepseek-coder:33b' => {
        strengths: %i[ruby python typescript javascript go rust java cpp],
        description: 'Enterprise-grade model for complex codebases',
        size: '19GB',
        tier: :premium,
        quality_score: 10
      }
    }.freeze

    def initialize
      @ollama_manager = OllamaManager.new
    end

    def select_optimal_model(languages, project_type: nil)
      # Get available models
      # available_models = @ollama_manager.list_models

      # # Score each model based on language compatibility
      # model_scores = {}
      # MODEL_CAPABILITIES.each do |model, capabilities|
      #   score = calculate_model_score(model, capabilities, languages)
      #   model_scores[model] = score if score > 0
      # end

      # # Return highest scoring model, fallback to default
      # best_model = model_scores.max_by { |_, score| score }&.first
      # best_model || 'deepseek-coder:6.7b'

      recommend_model_for_languages(languages)
    end

    def ensure_model_ready(model_name, languages: [], interactive: true)
      if @ollama_manager.model_available?(model_name)
        puts "✅ #{model_name} already available"
        return true
      end

      model_info = MODEL_CAPABILITIES[model_name]
      unless model_info
        puts "❌ Unknown model: #{model_name}".red
        return false
      end

      if interactive
        # Show download information and get consent
        puts "\n📦 Model Required: #{model_name}".cyan
        puts "   Size: #{model_info[:size]}"
        puts "   Tier: #{model_info[:tier].to_s.capitalize} (#{MODEL_TIERS[model_info[:tier]][:description]})"
        puts "   Download time: #{MODEL_TIERS[model_info[:tier]][:setup_time]}"
        
        # Suggest alternatives for large downloads
        if model_info[:tier] != :fast && languages.any?
          fast_alternative = recommend_model_for_languages(languages, tier: :fast)
          fast_info = MODEL_CAPABILITIES[fast_alternative]
          
          puts "\n💡 Quick alternative available:".yellow
          puts "   #{fast_alternative} (#{fast_info[:size]}) - #{fast_info[:description]}"
          puts
          
          print "Choose: [1] Download #{model_name} [2] Use #{fast_alternative} [3] Cancel: "
          choice = gets&.chomp || '3'
          
          case choice
          when '2'
            return ensure_model_ready(fast_alternative, languages: languages, interactive: false)
          when '3'
            puts "❌ Setup cancelled"
            return false
          end
        else
          print "Download #{model_name} (#{model_info[:size]})? [Y/n]: "
          choice = (gets&.chomp || 'y').downcase
          return false if choice == 'n' || choice == 'no'
        end
      end

      # Proceed with download with enhanced spinner
      download_message = "Downloading #{model_name} (#{model_info[:size]}) - #{MODEL_TIERS[model_info[:tier]][:setup_time]}"
      
      begin
        EnhancedSpinner.download(download_message) do
          @ollama_manager.pull_model!(model_name)
        end
        true
      rescue StandardError => e
        puts "❌ Download failed: #{e.message}".red
        false
      end
    end

    def build_review_prompt(language, content, file_path = nil)
      base_prompt = LANGUAGE_PROMPTS[language] || LANGUAGE_PROMPTS[:generic]
      language_name = language.to_s.capitalize
      file_ext = get_file_extension(language)

      <<~FULL_PROMPT
        #{base_prompt}

        Please analyze this #{language_name} code and provide specific, actionable feedback:

        #{file_path ? "File: #{file_path}" : ''}

        ```#{file_ext}
        #{content}
        ```

        Respond in JSON format with the following structure:
        {
          "score": <1-10 overall quality score>,
          "issues": [
            {
              "severity": "<critical|major|minor>",
              "description": "<specific issue description>",
              "line": <line number if applicable>,
              "suggestion": "<how to fix>"
            }
          ],
          "suggestions": [
            {
              "category": "<performance|security|maintainability|style>",
              "description": "<improvement suggestion>",
              "impact": "<high|medium|low>"
            }
          ],
          "positive_aspects": [
            "<things done well>"
          ],
          "summary": "<brief overall assessment>",
          "priority_actions": [
            "<top 3 most important improvements>"
          ]
        }
      FULL_PROMPT
    end

    def recommend_model_for_languages(languages, tier: :fast)
      # Get models for the specified tier
      tier_models = MODEL_CAPABILITIES.select { |_, info| info[:tier] == tier }
      
      # Find best match for languages within tier
      best_model = tier_models.max_by do |model, info|
        calculate_language_compatibility(info[:strengths], languages) * info[:quality_score]
      end
      
      if best_model
        best_model.first
      else
        # Fallback to best model in fast tier
        fallback_tier_models = MODEL_CAPABILITIES.select { |_, info| info[:tier] == :fast }
        fallback_model = fallback_tier_models.max_by do |model, info|
          calculate_language_compatibility(info[:strengths], languages) * info[:quality_score]
        end
        fallback_model&.first || 'codegemma:2b'
      end
    end

    def get_upgrade_suggestions(current_model, languages)
      current_info = MODEL_CAPABILITIES[current_model]
      return [] unless current_info

      current_tier = current_info[:tier]
      
      # Find better models in higher tiers
      upgrades = []
      
      MODEL_CAPABILITIES.each do |model, info|
        next if info[:tier] == current_tier || MODEL_TIERS[info[:tier]][:priority] <= MODEL_TIERS[current_tier][:priority]
        
        compatibility = calculate_language_compatibility(info[:strengths], languages)
        next if compatibility < 0.7 # Only suggest highly compatible models
        
        quality_improvement = info[:quality_score] - current_info[:quality_score]
        next if quality_improvement <= 0
        
        upgrades << {
          model: model,
          info: info,
          tier: info[:tier],
          compatibility: compatibility,
          quality_improvement: quality_improvement
        }
      end
      
      # Sort by quality improvement, then by compatibility
      upgrades.sort_by { |u| [-u[:quality_improvement], -u[:compatibility]] }
    end

    def get_models_by_tier(tier)
      MODEL_CAPABILITIES.select { |_, info| info[:tier] == tier }
    end

    def get_model_info(model_name)
      MODEL_CAPABILITIES[model_name] || {
        strengths: [],
        description: 'Unknown model',
        size: 'Unknown',
        tier: :fast,
        quality_score: 5
      }
    end

    private

    def calculate_language_compatibility(model_strengths, project_languages)
      return 0.0 if project_languages.empty? || model_strengths.empty?

      # Calculate how many of the project's languages are covered by the model
      covered_languages = project_languages & model_strengths
      compatibility = covered_languages.length.to_f / project_languages.length

      # Bonus for models that cover primary languages well
      if project_languages.first && model_strengths.include?(project_languages.first)
        compatibility += 0.2
      end

      [compatibility, 1.0].min
    end


    def list_recommended_models(languages)
      recommendations = []

      MODEL_CAPABILITIES.each do |model, info|
        compatibility = calculate_language_compatibility(info[:strengths], languages)
        next unless compatibility > 0.3 # 30% compatibility threshold

        recommendations << {
          model: model,
          compatibility: compatibility,
          info: info
        }
      end

      recommendations.sort_by { |rec| -rec[:compatibility] }
    end

    private

    def calculate_model_score(model, capabilities, languages)
      return 0 if capabilities[:strengths].empty?

      # Calculate overlap between model strengths and project languages
      overlap = (capabilities[:strengths] & languages).length
      total_languages = languages.length

      # Base score from language overlap
      base_score = (overlap.to_f / total_languages) * 100

      # Bonus for having primary language
      primary_bonus = capabilities[:strengths].include?(languages.first) ? 20 : 0

      base_score + primary_bonus
    end

    def calculate_language_compatibility(model_strengths, project_languages)
      return 0 if model_strengths.empty? || project_languages.empty?

      overlap = (model_strengths & project_languages).length
      overlap.to_f / project_languages.length
    end

    def get_file_extension(language)
      {
        ruby: 'ruby',
        python: 'python',
        typescript: 'typescript',
        javascript: 'javascript',
        go: 'go',
        rust: 'rust',
        css: 'css',
        html: 'html',
        java: 'java',
        cpp: 'cpp'
      }[language] || language.to_s
    end
  end
end
