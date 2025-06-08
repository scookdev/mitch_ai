# frozen_string_literal: true

require 'tty-spinner'

begin
  require 'tty-progressbar'
rescue LoadError
  # TTY::ProgressBar is optional for progress bar functionality
end

module MitchAI
  class EnhancedSpinner
    # SPECTACULAR spinner animations for different operations! 🎪
    SPINNER_TYPES = {
      # Download operations - animated progress with data flow
      download: {
        frames: ['📥 ⬇️💫 ', '📥 ⬇️⚡ ', '📥 ⬇️✨ ', '📥 ⬇️🌟 ', '📥 ⬇️💥 ', '📥 ⬇️🎉 '],
        interval: 0.3,
        format: :classic,
        success_message: '🎉 Download blazing fast complete!'
      },
      
      # AI analysis - brain with neural network activity
      analysis: {
        frames: ['🧠 🔮✨', '🧠 💫⚡', '🧠 🌟💭', '🧠 ✨🔥', '🧠 💡🚀', '🧠 🎯⭐'],
        interval: 0.4,
        format: :classic,
        success_message: '🧠 AI analysis complete - insights discovered!'
      },
      
      # File operations - folders with sparkles and search beams
      files: {
        frames: ['📁 🔍✨', '📂 🔍💫', '📁 🔍⚡', '📂 🔍🌟', '📁 🔍💥', '📂 🔍🎊'],
        interval: 0.35,
        format: :classic,
        success_message: '📂 Files discovered and catalogued!'
      },
      
      # Server operations - network with data packets
      server: {
        frames: ['🌐 💫●○○', '🌐 ⚡○●○', '🌐 ✨○○●', '🌐 🌟○●○', '🌐 💥●○○', '🌐 🎉○●○'],
        interval: 0.25,
        format: :classic,
        success_message: '🌐 Server launched and ready for action!'
      },
      
      # Model operations - robot with power-up sequence
      model: {
        frames: ['🤖 ⚙️💫', '🤖 🔧⚡', '🤖 🔩✨', '🤖 ⚡🌟', '🤖 🚀💥', '🤖 ✅🎉'],
        interval: 0.4,
        format: :classic,
        success_message: '🤖 AI model locked and loaded!'
      },
      
      # Setup operations - rocket launch sequence
      setup: {
        frames: ['🚀 🔧💫', '🚀 ⚙️⚡', '🚀 🔩✨', '🚀 ⚡🌟', '🚀 💥🎆', '🚀 🎊🎉'],
        interval: 0.35,
        format: :classic,
        success_message: '🚀 Setup complete - ready for liftoff!'
      },
      
      # Processing - energy waves and particles
      processing: {
        frames: ['⚡ ◐💫○○', '⚡ ◓⚡○○', '⚡ ◑✨○○', '⚡ ◒🌟○', '⚡ ●💥○○', '⚡ ●🎉●○', '⚡ ●🎊●●', '⚡ ○✨●●'],
        interval: 0.15,
        format: :classic,
        success_message: '⚡ Processing complete with lightning speed!'
      },
      
      # Success celebration - fireworks and party
      success: {
        frames: ['🎉 ✨⭐', '🎊 💫🌟', '🎆 ⚡💥', '🎇 🌈✨', '🎉 🎊🎆', '🌟 💫⭐'],
        interval: 0.2,
        format: :classic,
        success_message: '🎉 Mission accomplished with style!'
      },
      
      # Epic mode - for extra special operations
      epic: {
        frames: ['⚡🔥💫🌟', '🌟⚡💥✨', '💥🌈🔥💫', '✨🎆⚡🌟', '🔥💫🎊💥', '🌟✨🎉⚡'],
        interval: 0.3,
        format: :classic,
        success_message: '🌟 EPIC SUCCESS! You are legendary!'
      },
      
      # Thinking - for deep AI contemplation
      thinking: {
        frames: ['🤔 💭...', '🤔 💭💭.', '🤔 💭💭💭', '🤔 💡💭💭', '🤔 💡💡💭', '🤔 💡💡💡'],
        interval: 0.5,
        format: :classic,
        success_message: '💡 Eureka! Solution found!'
      },
      
      # Magic - for the most amazing operations
      magic: {
        frames: ['🪄 ✨💫⭐', '🔮 💫✨🌟', '✨ 🌟💫⭐', '💫 ⭐✨🌟', '🌟 💫⭐✨', '⭐ ✨🌟💫'],
        interval: 0.25,
        format: :classic,
        success_message: '🪄 Pure magic! Absolutely spectacular!'
      }
    }.freeze

    def self.create(type, message, &block)
      spinner_config = SPINNER_TYPES[type] || SPINNER_TYPES[:processing]
      
      spinner = TTY::Spinner.new(
        "[:spinner] #{message}",
        format: spinner_config[:format],
        frames: spinner_config[:frames],
        interval: spinner_config[:interval]
      )
      
      if block_given?
        spinner.auto_spin
        result = yield
        # Use the spectacular custom success message from the spinner config!
        success_msg = spinner_config[:success_message] || "✅ #{message.gsub(/\.+$/, '')} complete!"
        spinner.success(success_msg)
        result
      else
        spinner
      end
    end

    # Convenience methods for different operation types
    def self.download(message, &block)
      create(:download, message, &block)
    end

    def self.analysis(message, &block)
      create(:analysis, message, &block)
    end

    def self.files(message, &block)
      create(:files, message, &block)
    end

    def self.server(message, &block)
      create(:server, message, &block)
    end

    def self.model(message, &block)
      create(:model, message, &block)
    end

    def self.setup(message, &block)
      create(:setup, message, &block)
    end

    def self.processing(message, &block)
      create(:processing, message, &block)
    end

    def self.epic(message, &block)
      create(:epic, message, &block)
    end

    def self.thinking(message, &block)
      create(:thinking, message, &block)
    end

    def self.magic(message, &block)
      create(:magic, message, &block)
    end

    def self.success(message, &block)
      create(:success, message, &block)
    end

    # Multi-step operations with different spinners
    def self.multi_step(steps)
      results = []
      
      steps.each do |step|
        type = step[:type] || :processing
        message = step[:message]
        action = step[:action]
        
        result = create(type, message) do
          action.call
        end
        
        results << result
        sleep(0.1) # Brief pause between steps
      end
      
      results
    end

    # Progress bar style for long operations
    def self.progress_bar(message, total_steps, &block)
      if defined?(TTY::ProgressBar)
        bar = TTY::ProgressBar.new(
          "#{message} [:bar] :percent :eta",
          total: total_steps,
          bar_format: :block
        )
        
        if block_given?
          yield(bar)
        else
          bar
        end
      else
        # Fallback to regular spinner if TTY::ProgressBar not available
        create(:processing, "#{message} (#{total_steps} steps)", &block)
      end
    end
  end
end