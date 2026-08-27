require "json"
require "net/http"
require "uri"

class AiAnswerGenerator
  Result = Data.define(:answer, :error_message) do
    def success?
      error_message.blank?
    end
  end

  def self.call(question:, knowledges:)
    new(question:, knowledges:).call
  end

  def initialize(question:, knowledges:)
    @question = question
    @knowledges = knowledges
  end

  def call
    response = post_response
    if response.code.to_i >= 400
      log_api_failure(response)
      return failure
    end

    answer = extract_answer(JSON.parse(response.body))
    return failure if answer.blank?

    Result.new(answer:, error_message: nil)
  rescue KeyError, JSON::ParserError, StandardError
    failure
  end

  private

  attr_reader :question, :knowledges

  def post_response
    uri = URI("https://api.openai.com/v1/responses")
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
      model: ENV.fetch("OPENAI_MODEL", "gpt-5"),
      store: false,
      input: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: user_prompt
        }
      ]
    }
  end

  def system_prompt
    <<~PROMPT
      あなたは社内ナレッジを根拠に回答するアシスタントです。
      渡された社内ナレッジだけを根拠に回答してください。
      社内ナレッジに書かれていない内容は推測しないでください。
      答えが社内ナレッジにない場合は「関連する社内ナレッジには回答に必要な情報が見つかりませんでした」と明示してください。
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      [ユーザーの質問]
      #{question}

      [社内ナレッジ]
      #{knowledge_context}
    PROMPT
  end

  def knowledge_context
    knowledges.each_with_index.map do |knowledge, index|
      <<~KNOWLEDGE
        #{index + 1}.
        タイトル: #{knowledge.title}
        カテゴリ: #{knowledge.category}
        本文: #{knowledge.content}
      KNOWLEDGE
    end.join("\n")
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY")
  end

  def extract_answer(response_body)
    response_body.fetch("output", []).find { |item| item["type"] == "message" && item["role"] == "assistant" }
      &.fetch("content", [])
      &.find { |content| content["type"] == "output_text" }
      &.fetch("text", nil)
  end

  def log_api_failure(response)
    Rails.logger.warn(
      "OpenAI API request failed: status=#{response.code}, request_id=#{response["request-id"] || response["x-request-id"]}"
    )
  end

  def failure
    Result.new(answer: nil, error_message: "AI回答の生成に失敗しました。関連ナレッジを確認してください。")
  end
end
