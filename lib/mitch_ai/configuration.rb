# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'thor'

module MitchAI
  class Configuration
    CONFIG_FILE = File.expand_path('~/.mitch_ai.yml')

    attr_accessor :api_key, :provider, :languages

    def initialize
      @provider = :openai
      @languages = %i[ruby python javascript]
      @api_key = ENV.fetch('OPENAI_API_KEY', nil) # Check environment variable first
      load_config unless @api_key # Only load from config if not already set
    end

    def configure_api_key(provider)
      print "Enter your #{provider.upcase} API key: "
      api_key = ask_securely

      # Validate API key (basic check)
      if valid_api_key?(api_key)
        save_api_key(provider, api_key)
        puts 'API key saved successfully!'
      else
        puts 'Invalid API key. Please try again.'
      end
    end

    private

    def load_config
      return unless File.exist?(CONFIG_FILE)

      config = YAML.load_file(CONFIG_FILE)
      config = symbolize_keys(config) if config.is_a?(Hash)

      @api_key = config.dig(:openai, :api_key)
      # Don't override default provider if not needed
    end

    # rubocop:disable Metrics/MethodLength
    def save_api_key(provider, api_key)
      # Ensure config directory exists
      FileUtils.mkdir_p(File.dirname(CONFIG_FILE))

      # Save to config file
      config = begin
        yaml_config = YAML.load_file(CONFIG_FILE)
        symbolize_keys(yaml_config) if yaml_config.is_a?(Hash)
      rescue StandardError
        {}
      end

      provider_sym = provider.to_sym
      config[provider_sym] ||= {}
      config[provider_sym][:api_key] = api_key

      File.write(CONFIG_FILE, config.to_yaml)

      # Set secure permissions
      File.chmod(0o600, CONFIG_FILE)

      # Update current instance
      @api_key = api_key
    end
    # rubocop:enable Metrics/MethodLength

    def symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
      end
    end

    def valid_api_key?(key)
      # Basic validation - can be expanded
      key && key.length > 20
    end

    def ask_securely
      # Use system's secure input method
      `stty -echo`
      print 'API Key: '
      api_key = $stdin.gets.chomp
      `stty echo`
      puts "\n"
      api_key
    end
  end
end

# CLI integration
class CLI < Thor
  desc 'configure', 'Configure API credentials'
  option :provider, default: 'openai', desc: 'AI provider to configure'
  def configure
    config = CodeReviewAI::Configuration.new
    config.configure_api_key(options[:provider])
  end
end
