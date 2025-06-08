# frozen_string_literal: true

require_relative 'commands/review_command'
require_relative 'commands/setup_command'
require_relative 'commands/info_commands'
require_relative 'commands/server_command'
require_relative 'commands/models_command'

module MitchAI
  class CLI
    def self.start(args)
      command = args[0]
      execute_command(command, args)
    rescue StandardError => e
      handle_error(e, args)
    end

    private_class_method def self.execute_command(command, args)
      case command
      when 'review' then Commands::ReviewCommand.call(args[1..])
      when 'setup' then Commands::SetupCommand.call(args[1..])
      when 'server' then Commands::ServerCommand.call(args[1..])
      when 'languages' then Commands::LanguagesCommand.call(args[1..])
      when 'models' then Commands::ModelsCommand.call(args[1..])
      when 'version', '-v', '--version' then Commands::VersionCommand.call(args[1..])
      when 'help', '-h', '--help', nil then Commands::HelpCommand.call(args[1..])
      else show_unknown_command(command)
      end
    end

    private_class_method def self.handle_error(error, args)
      puts "💥 Error: #{error.message}".red
      puts 'Try: mitch-ai help' unless args.include?('-v')
      exit 1
    end

    private_class_method def self.show_unknown_command(command)
      puts "❌ Unknown command: #{command}"
      puts 'Try: mitch-ai help'
      exit 1
    end
  end
end

# Add colorize support if available
begin
  require 'colorize'
rescue LoadError
  # Define color methods as no-ops if colorize isn't available
  class String
    %i[red green yellow blue cyan white].each do |color|
      define_method(color) { self }
    end
  end
end