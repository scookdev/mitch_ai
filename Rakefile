# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Default task runs tests and linting
task default: %i[spec rubocop]

# RSpec task
RSpec::Core::RakeTask.new(:spec)

# RuboCop task
RuboCop::RakeTask.new

# Custom tasks
namespace :mitch_ai do
  desc 'Setup development environment'
  task :setup do
    puts '🚀 Setting up Mitch-AI development environment...'

    # Install dependencies
    sh 'bundle install'

    # Check if Ollama is installed
    if system('which ollama > /dev/null 2>&1')
      puts '✅ Ollama found'
    else
      puts '❌ Ollama not found. Install from: https://ollama.ai'
    end

    # Check if test model is available
    if system('ollama list | grep -q deepseek-coder:6.7b')
      puts '✅ Test model available'
    else
      puts '📥 Pulling test model (this may take a while)...'
      sh 'ollama pull deepseek-coder:6.7b'
    end

    puts '🎉 Development environment ready!'
  end

  desc 'Start test environment'
  task :test_env do
    puts '🔧 Starting test environment...'

    # Start Ollama if not running
    unless system('curl -s http://localhost:11434/api/version > /dev/null 2>&1')
      puts '🔄 Starting Ollama...'
      spawn('ollama serve')
      sleep(3)
    end

    puts '✅ Test environment ready'
  end

  desc 'Run integration tests'
  task :integration do
    Rake::Task['mitch_ai:test_env'].invoke
    sh 'rspec spec/integration_spec.rb'
  end

  desc 'Build and install gem locally'
  task :install_local do
    sh 'gem build mitch-ai.gemspec'
    gem_file = Dir['mitch-ai-*.gem'].sort.last
    sh "gem install #{gem_file}"
    puts '✅ Gem installed locally'
  end

  desc 'Clean up build artifacts'
  task :clean do
    sh 'rm -f *.gem'
    puts '✅ Cleaned up'
  end
end

# YARD documentation
begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb']
    t.options = ['--markup-provider=redcarpet', '--markup=markdown']
  end
rescue LoadError
  puts 'YARD not available. Install with: gem install yard'
end
