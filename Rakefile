# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

# Add a console task for interactive testing
desc 'Open an interactive console with the gem loaded'
task :console do
  require 'irb'
  require 'irb/completion'
  require 'mitch_ai'
  ARGV.clear
  IRB.start
end

# Add a task to run the CLI tool directly
desc 'Run the MitchAI tool'
task :run, [:command, :args] do |_t, args|
  command = args[:command] || 'help'
  cli_args = args[:args] || ''

  # Add lib to load path
  $LOAD_PATH.unshift(File.expand_path('lib', __dir__))
  require 'mitch_ai'

  system "ruby -Ilib exe/mitch_ai #{command} #{cli_args}"
end
