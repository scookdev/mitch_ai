# frozen_string_literal: true

require 'simplecov'
require 'codecov'

SimpleCov.start do
  add_filter '/spec/'
  add_group 'Lib', 'lib'
end

SimpleCov.formatter = SimpleCov::Formatter::Codecov
