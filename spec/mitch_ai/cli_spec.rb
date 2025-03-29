# frozen_string_literal: true

require 'spec_helper'
require 'mitch_ai/cli'

RSpec.describe MitchAI::CLI do
  describe '#review' do
    let(:cli) { described_class.new }

    context 'with a valid file path' do
      let(:sample_file) { File.expand_path('spec/fixtures/sample.rb') }

      before do
        # Ensure sample file exists
        FileUtils.mkdir_p(File.dirname(sample_file))
        File.write(sample_file, "def hello\n  puts 'world'\nend")
      end

      it 'processes a ruby file' do
        expect(cli).to receive(:analyze_file).and_return({
                                                           file_path: sample_file,
                                                           language: 'Ruby',
                                                           suggestions: ['Looks good!']
                                                         })

        # Capture stdout
        expect { cli.review(sample_file) }.to output(/Ruby/).to_stdout
      end
    end

    context 'without API key' do
      it 'raises an error' do
        allow_any_instance_of(MitchAI::Configuration).to receive(:api_key).and_return(nil)

        expect { cli.review('some_file.rb') }.to raise_error(SystemExit)
      end
    end
  end
end
