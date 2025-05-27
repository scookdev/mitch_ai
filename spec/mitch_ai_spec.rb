# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MitchAI do
  it 'has a version number' do
    expect(MitchAI::VERSION).not_to be nil
  end

  describe '.review' do
    it 'provides backward compatibility' do
      result = MitchAI.review(sample_ruby_code)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:issues)
      expect(result).to have_key(:suggestions)
      expect(result).to have_key(:score)
      expect(result[:legacy]).to be true
    end
  end

  describe '.enhanced_reviewer' do
    it 'creates an enhanced reviewer instance' do
      reviewer = MitchAI.enhanced_reviewer
      expect(reviewer).to be_a(MitchAI::EnhancedReviewer)
    end
  end

  describe '.ready?' do
    context 'when services are not running' do
      it 'returns false' do
        allow(MitchAI).to receive(:ollama_running?).and_return(false)
        allow(MitchAI).to receive(:mcp_server_running?).and_return(false)

        expect(MitchAI.ready?).to be false
      end
    end

    context 'when services are running' do
      it 'returns true' do
        allow(MitchAI).to receive(:ollama_running?).and_return(true)
        allow(MitchAI).to receive(:mcp_server_running?).and_return(true)

        expect(MitchAI.ready?).to be true
      end
    end
  end
end
