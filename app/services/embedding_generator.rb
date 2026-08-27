require "json"
require "net/http"
require "uri"

class EmbeddingGenerator
  DEFAULT_MODEL = "text-embedding-3-small"
  ENDPOINT = "https://api.openai.com/v1/embeddings"

  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text.to_s
  end

  def call
    return nil if text.blank?

    response = post_response
    if response.code.to_i >= 400
      log_api_failure(response)
      return nil
    end

    extract_embedding(JSON.parse(response.body))
  rescue KeyError, JSON::ParserError, StandardError
    nil
  end

  private

  attr_reader :text

  def post_response
    uri = URI(ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def request_body
    {
      model: model,
      input: text
    }
  end

  def model
    ENV.fetch("OPENAI_EMBEDDING_MODEL", DEFAULT_MODEL)
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY")
  end

  def extract_embedding(response_body)
    embedding = response_body.fetch("data", []).first&.fetch("embedding", nil)
    return nil unless embedding.is_a?(Array)

    embedding
  end

  def log_api_failure(response)
    Rails.logger.warn(
      "OpenAI Embeddings API request failed: status=#{response.code}, request_id=#{response["request-id"] || response["x-request-id"]}"
    )
  end
end
