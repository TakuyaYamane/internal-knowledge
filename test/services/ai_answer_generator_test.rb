require "test_helper"

class AiAnswerGeneratorTest < ActiveSupport::TestCase
  FakeResponse = Data.define(:code, :body)

  test "returns generated answer" do
    knowledge = Knowledge.new(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )
    generator = AiAnswerGenerator.new(question: "VPNはどう使いますか？", knowledges: [ knowledge ])
    response = FakeResponse.new("200", {
      output: [
        {
          type: "message",
          role: "assistant",
          content: [
            {
              type: "output_text",
              text: "VPNクライアントを起動してください."
            }
          ]
        }
      ]
    }.to_json)
    generator.define_singleton_method(:post_response) { response }

    result = generator.call

    assert result.success?
    assert_equal "VPNクライアントを起動してください.", result.answer
    assert_nil result.error_message
  end

  test "returns failure when response does not include output text" do
    knowledge = Knowledge.new(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )
    generator = AiAnswerGenerator.new(question: "VPNはどう使いますか？", knowledges: [ knowledge ])
    response = FakeResponse.new("200", { output: [] }.to_json)
    generator.define_singleton_method(:post_response) { response }

    result = generator.call

    assert_not result.success?
    assert_nil result.answer
    assert_equal "AI回答の生成に失敗しました。関連ナレッジを確認してください。", result.error_message
  end

  test "returns failure when api request fails" do
    knowledge = Knowledge.new(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )
    generator = AiAnswerGenerator.new(question: "VPNはどう使いますか？", knowledges: [ knowledge ])
    response = FakeResponse.new("500", { error: { message: "error" } }.to_json)
    generator.define_singleton_method(:post_response) { response }

    result = generator.call

    assert_not result.success?
    assert_nil result.answer
    assert_equal "AI回答の生成に失敗しました。関連ナレッジを確認してください。", result.error_message
  end
end
