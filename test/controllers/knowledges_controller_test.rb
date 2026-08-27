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
    assert_select "h2 a[href='#{knowledge_path(Knowledge.last)}']", "経費精算の方法"
    assert_select "p", text: "カテゴリ: 経費"
    assert_select "p", text: "経費精算はシステムから申請してください。"
  end

  test "should show knowledge" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動し、社員アカウントでログインしてください。",
      category: "IT"
    )

    get knowledge_url(knowledge)

    assert_response :success
    assert_select "h1", "VPNへの接続方法"
    assert_select "p", text: "カテゴリ: IT"
    assert_select "p", text: "VPNクライアントを起動し、社員アカウントでログインしてください。"
    assert_select "a[href='#{knowledges_path}']", "一覧へ戻る"
  end

  test "should return not found for missing knowledge" do
    get knowledge_url(id: 999_999)

    assert_response :not_found
  end

  test "should get new" do
    get new_knowledge_url

    assert_response :success
    assert_select "h1", "ナレッジ新規登録"
    assert_select "form[action='#{knowledges_path}'][method='post']"
    assert_select "input[name='knowledge[title]']"
    assert_select "input[name='knowledge[category]']"
    assert_select "textarea[name='knowledge[content]']"
  end

  test "should create knowledge" do
    assert_difference("Knowledge.count", 1) do
      post knowledges_url, params: {
        knowledge: {
          title: "VPNへの接続方法",
          content: "VPNクライアントを起動し、社員アカウントでログインしてください。",
          category: "IT"
        }
      }
    end

    assert_redirected_to knowledges_url
    follow_redirect!
    assert_response :success
    assert_select "p", text: "ナレッジを登録しました。"
    assert_select "h2", "VPNへの接続方法"
  end

  test "should render new with errors when validation fails" do
    assert_no_difference("Knowledge.count") do
      post knowledges_url, params: {
        knowledge: {
          title: "",
          content: "",
          category: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "ナレッジ新規登録"
    assert_select "p", text: "入力内容を確認してください。"
    assert_select "li", text: "Title can't be blank"
    assert_select "li", text: "Content can't be blank"
    assert_select "li", text: "Category can't be blank"
  end
end
