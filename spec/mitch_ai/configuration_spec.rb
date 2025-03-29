# frozen_string_literal: true

require 'spec_helper'
require 'mitch_ai/configuration'

RSpec.describe MitchAI::Configuration do
  let(:config) { described_class.new }

  describe 'initialization' do
    it 'creates a new configuration' do
      expect(config).to be_a(MitchAI::Configuration)
    end

    it 'has default settings' do
      expect(config.provider).to eq(:openai)
      expect(config.languages).to include(:ruby)
    end
  end

  describe '#configure' do
    it 'allows setting custom configuration' do
      config.provider = :anthropic
      config.languages = [:python]

      expect(config.provider).to eq(:anthropic)
      expect(config.languages).to eq([:python])
    end
  end
end
