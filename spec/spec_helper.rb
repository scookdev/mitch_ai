# frozen_string_literal: true

ENV['RSPEC_RUNNING'] = 'true'

require 'bundler/setup'
require 'mitch_ai'
require 'fileutils'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
