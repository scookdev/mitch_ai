# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module MitchAI
  class OllamaClient
    def initialize(base_url = 'http://localhost:11434')
      @base_url = base_url
    end

    def chat(model, messages, stream: false)
      uri = URI("#{@base_url}/api/chat")

      payload = {
        model: model,
        messages: messages,
        stream: stream
      }

      response = Net::HTTP.post(uri, payload.to_json, 'Content-Type' => 'application/json')

      if stream
        # Handle streaming response
        response.body.split("\n").map do |line|
          JSON.parse(line) if line.strip != ''
        end.compact
      else
        JSON.parse(response.body)
      end
    end

    def available_models
      uri = URI("#{@base_url}/api/tags")
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)['models']
    end
  end
end
