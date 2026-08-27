require "test_helper"

class KnowledgesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    get knowledges_url

    assert_response :success
    assert_select "h1", "社内ナレッジ一覧"
    assert_select "h2", "経費精算の方法"
    assert_select "p", text: "カテゴリ: 経費"
    assert_select "p", text: "経費精算はシステムから申請してください。"
  end
end
