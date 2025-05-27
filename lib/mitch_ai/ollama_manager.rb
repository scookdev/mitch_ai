# frozen_string_literal: true

require 'open3'
require 'fileutils'
require 'logger'
require 'net/http'
require 'rbconfig'
require 'tty-spinner'

module MitchAI
  class OllamaManager
    DEFAULT_MODEL = 'deepseek-coder:6.7b'
    OLLAMA_PORT = 11_434

    def initialize
      @logger = Logger.new($stdout)
    end

    # Complete Ollama setup - installs, starts, and pulls model
    def setup!(model: DEFAULT_MODEL, force: false)
      spinner = TTY::Spinner.new('[:spinner] 🚀 Setting up Ollama for Mitch-Ai', format: :dots)
      spinner.auto_spin

      # Step 1: Install Ollama if needed
      install_ollama! unless ollama_installed? && !force

      # Step 2: Start Ollama service
      start_ollama! unless ollama_running?

      # Step 3: Pull the model
      pull_model!(model) unless model_available?(model) && !force

      # Step 4: Verify everything works
      verify_setup!(model)

      spinner.success("✅ Ollama setup complete! Model '#{model}' is ready.")
    end

    # Install Ollama automatically
    def install_ollama!
      if ollama_installed?
        @logger.info '✅ Ollama already installed'
        return
      end

      @logger.info '📦 Installing Ollama...'

      case detect_os
      when :macos
        install_ollama_macos
      when :linux
        install_ollama_linux
      when :windows
        install_ollama_windows
      else
        raise 'Unsupported operating system'
      end

      @logger.info '✅ Ollama installed successfully'
    end

    # Start Ollama service
    def start_ollama!
      if ollama_running?
        @logger.info '✅ Ollama already running'
        return
      end

      @logger.info '🔄 Starting Ollama service...'

      case detect_os
      when :macos, :linux
        start_ollama_unix
      when :windows
        start_ollama_windows
      end

      # Wait for Ollama to be ready
      wait_for_ollama

      @logger.info '✅ Ollama service started'
    end

    # Pull a specific model
    def pull_model!(model)
      if model_available?(model)
        @logger.info "✅ Model '#{model}' already available"
        return
      end

      @logger.info "📥 Pulling model '#{model}' (this may take a while)..."
      @logger.info '    ☕ Grab some coffee - large models can take 5-15 minutes'

      success = false
      output = ''

      # Show progress while pulling
      Open3.popen3("ollama pull #{model}") do |stdin, stdout, stderr, thread|
        stdin.close

        # Read both stdout and stderr
        [stdout, stderr].each do |stream|
          Thread.new do
            stream.each_line do |line|
              output += line
              # Show progress for large downloads
              if line.include?('%') || line.include?('pulling')
                print "\r    #{line.strip}"
                $stdout.flush
              end
            end
          end
        end

        success = thread.value.success?
      end

      print "\n" # New line after progress

      if success
        @logger.info "✅ Model '#{model}' downloaded successfully"
      else
        @logger.error "❌ Failed to download model '#{model}'"
        @logger.error "Output: #{output}"
        raise 'Model download failed'
      end
    end

    # Check if Ollama is installed
    def ollama_installed?
      system('which ollama > /dev/null 2>&1')
    end

    # Check if Ollama service is running
    def ollama_running?
      response = Net::HTTP.get_response(URI("http://localhost:#{OLLAMA_PORT}/api/version"))
      response.code == '200'
    rescue StandardError
      false
    end

    # Check if a specific model is available
    def model_available?(model)
      return false unless ollama_running?

      begin
        output = `ollama list 2>/dev/null`
        output.include?(model)
      rescue StandardError
        false
      end
    end

    # List all available models
    def available_models
      return [] unless ollama_running?

      begin
        output = `ollama list 2>/dev/null`
        lines = output.split("\n")[1..-1] # Skip header
        lines.map { |line| line.split.first }.compact
      rescue StandardError
        []
      end
    end

    # Get recommended model based on system resources
    def recommended_model
      total_ram = system_ram_gb

      case total_ram
      when 0..7
        'deepseek-coder:1.3b'  # Lightweight
      when 8..15
        'deepseek-coder:6.7b'  # Default
      when 16..31
        'deepseek-coder:33b'   # Better quality
      else
        'deepseek-coder:33b'   # Best quality
      end
    end

    # Interactive model selection
    def select_model_interactively
      puts "\n🧠 Choose your AI model:"
      puts '   Model size affects quality vs. speed vs. memory usage'
      puts

      models = [
        { name: 'deepseek-coder:1.3b', size: '1GB', desc: 'Fastest, lowest memory (4GB RAM+)' },
        { name: 'deepseek-coder:6.7b', size: '4GB', desc: 'Balanced, recommended (8GB RAM+)' },
        { name: 'deepseek-coder:33b', size: '19GB', desc: 'Best quality, slower (32GB RAM+)' },
        { name: 'codellama:7b', size: '4GB', desc: 'Alternative model (8GB RAM+)' }
      ]

      models.each_with_index do |model, i|
        marker = model[:name] == recommended_model ? '⭐' : '  '
        puts "#{marker} #{i + 1}. #{model[:name]} (#{model[:size]}) - #{model[:desc]}"
      end

      puts
      print "Enter choice (1-#{models.length}) [default: #{recommended_model}]: "

      choice = STDIN.gets.strip

      if choice.empty?
        recommended_model
      elsif choice.to_i.between?(1, models.length)
        models[choice.to_i - 1][:name]
      else
        puts 'Invalid choice, using recommended model'
        recommended_model
      end
    end

    # Health check
    def health_check
      status = {
        ollama_installed: ollama_installed?,
        ollama_running: ollama_running?,
        available_models: available_models,
        system_ram_gb: system_ram_gb,
        recommended_model: recommended_model
      }

      puts '🏥 Ollama Health Check:'
      puts "   Installed: #{status[:ollama_installed] ? '✅' : '❌'}"
      puts "   Running: #{status[:ollama_running] ? '✅' : '❌'}"
      puts "   Models: #{status[:available_models].length} available"
      puts "   System RAM: #{status[:system_ram_gb]}GB"
      puts "   Recommended: #{status[:recommended_model]}"

      status
    end

    private

    def detect_os
      case RbConfig::CONFIG['host_os']
      when /darwin/
        :macos
      when /linux/
        :linux
      when /mswin|mingw|cygwin/
        :windows
      else
        :unknown
      end
    end

    def install_ollama_macos
      if system('which brew > /dev/null 2>&1')
        # Use Homebrew if available
        system('brew install ollama') || raise('Homebrew install failed')
      else
        # Use official installer
        system('curl -fsSL https://ollama.ai/install.sh | sh') || raise('Official installer failed')
      end
    end

    def install_ollama_linux
      # Use official installer
      system('curl -fsSL https://ollama.ai/install.sh | sh') || raise('Installation failed')
    end

    def install_ollama_windows
      puts '⚠️  Windows installation requires manual setup:'
      puts '   1. Download Ollama from: https://ollama.ai/download'
      puts '   2. Run the installer'
      puts "   3. Run 'mitch-ai setup' again"
      puts
      puts 'Press Enter after installing Ollama...'
      STDIN.gets

      return if ollama_installed?

      raise 'Ollama installation not detected. Please install manually.'
    end

    def start_ollama_unix
      # Try to start as service first, then as background process
      if system('which systemctl > /dev/null 2>&1')
        # SystemD
        unless system('sudo systemctl start ollama 2>/dev/null')
          # Fallback to background process
          spawn('ollama serve > /dev/null 2>&1 &')
        end
      elsif system('which launchctl > /dev/null 2>&1')
        # macOS
        spawn('ollama serve > /dev/null 2>&1 &') unless system('launchctl start ollama 2>/dev/null')
      else
        # Generic Unix
        spawn('ollama serve > /dev/null 2>&1 &')
      end
    end

    def start_ollama_windows
      # Windows service or background process
      spawn('ollama serve')
    end

    def wait_for_ollama(timeout: 30)
      start_time = Time.now

      loop do
        break if ollama_running?

        raise "Ollama failed to start within #{timeout} seconds" if Time.now - start_time > timeout

        sleep(1)
      end
    end

    def verify_setup!(model)
      raise 'Ollama installation verification failed' unless ollama_installed?

      raise 'Ollama service verification failed' unless ollama_running?

      raise "Model '#{model}' verification failed" unless model_available?(model)

      # Quick test
      begin
        require_relative 'ollama_client'
        client = OllamaClient.new
        response = client.chat(model, [{ role: 'user', content: 'Hello' }])
        raise 'Model communication test failed' unless response&.dig('message', 'content')
      rescue StandardError => e
        raise "Model functionality test failed: #{e.message}"
      end
    end

    def system_ram_gb
      case detect_os
      when :macos
        `sysctl -n hw.memsize`.to_i / (1024**3)
      when :linux
        `grep MemTotal /proc/meminfo`.scan(/\d+/).first.to_i / (1024**2)
      when :windows
        `wmic computersystem get TotalPhysicalMemory /value`.scan(/\d+/).first.to_i / (1024**3)
      else
        8 # Reasonable default
      end
    rescue StandardError
      8 # Fallback
    end
  end
end
