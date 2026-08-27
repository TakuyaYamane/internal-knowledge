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
end
