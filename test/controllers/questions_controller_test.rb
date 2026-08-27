require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_question_url

    assert_response :success
    assert_select "h1", "社内質問"
    assert_select "form[action='#{questions_path}'][method='get']"
    assert_select "textarea[name='question']"
    assert_select "input[type='submit'][value='質問する']"
  end

  test "should display matching knowledges for question" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )

    get questions_url(question: "VPN")

    assert_response :success
    assert_select "h1", "質問結果"
    assert_select "textarea[name='question']", "VPN"
    assert_select "h2", "関連するナレッジ"
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
    assert_select "p", text: "カテゴリ: IT"
  end

  test "should display ai answer when matching knowledges exist" do
    Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )
    result = AiAnswerGenerator::Result.new(
      answer: "VPNを利用してください。",
      error_message: nil
    )

    with_ai_answer_generator(result) do
      get questions_url(question: "VPN")
    end

    assert_response :success
    assert_select "h2", "AI回答"
    assert_select "p", text: "VPNを利用してください。"
  end

  test "should not display unmatched knowledges" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    get questions_url(question: "VPN")

    assert_response :success
    assert_select "h3", text: "経費精算の方法", count: 0
    assert_select "p", text: "関連するナレッジは見つかりませんでした。"
  end

  test "should not call ai answer generator without matching knowledges" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    with_ai_answer_generator(->(*) { raise "should not be called" }) do
      get questions_url(question: "VPN")
    end

    assert_response :success
    assert_select "p", text: "関連するナレッジが見つからなかったため、AI回答は生成しませんでした"
  end

  test "should display ai failure message and matching knowledges" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )
    result = AiAnswerGenerator::Result.new(
      answer: nil,
      error_message: "AI回答の生成に失敗しました。関連ナレッジを確認してください。"
    )

    with_ai_answer_generator(result) do
      get questions_url(question: "VPN")
    end

    assert_response :success
    assert_select "p", text: "AI回答の生成に失敗しました。関連ナレッジを確認してください。"
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
  end

  test "should handle blank question" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    get questions_url(question: "")

    assert_response :success
    assert_select "p", text: "質問を入力してください。"
    assert_select "h3", text: "経費精算の方法", count: 0
  end

  private

  def with_ai_answer_generator(result)
    original = AiAnswerGenerator.method(:call)

    AiAnswerGenerator.define_singleton_method(:call) do |**arguments|
      result.respond_to?(:call) ? result.call(**arguments) : result
    end

    yield
  ensure
    AiAnswerGenerator.define_singleton_method(:call, original)
  end
end
