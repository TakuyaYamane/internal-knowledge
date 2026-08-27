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

  test "index displays search form" do
    get knowledges_url

    assert_response :success
    assert_select "form[action='#{knowledges_path}'][method='get']"
    assert_select "input[name='q']"
    assert_select "input[type='submit'][value='検索']"
  end

  test "index displays search results" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    get knowledges_url(q: "経費")

    assert_response :success
    assert_select "input[name='q'][value='経費']"
    assert_select "h2 a[href='#{knowledge_path(knowledge)}']", "経費精算の方法"
  end

  test "index does not display unmatched search results" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )
    Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )

    get knowledges_url(q: "経費")

    assert_response :success
    assert_select "h2", text: "経費精算の方法"
    assert_select "h2", text: "VPNへの接続方法", count: 0
  end

  test "index displays all knowledges with blank search query" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )
    Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )

    get knowledges_url(q: "")

    assert_response :success
    assert_select "h2", text: "経費精算の方法"
    assert_select "h2", text: "VPNへの接続方法"
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
    assert_select "a[href='#{edit_knowledge_path(knowledge)}']", "編集"
    assert_select "form[action='#{knowledge_path(knowledge)}'][method='post']"
    assert_select "button", "削除"
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
    with_knowledge_embedding_sync(true) do
      assert_difference("Knowledge.count", 1) do
        post knowledges_url, params: {
          knowledge: {
            title: "VPNへの接続方法",
            content: "VPNクライアントを起動し、社員アカウントでログインしてください。",
            category: "IT"
          }
        }
      end
    end

    assert_redirected_to knowledges_url
    follow_redirect!
    assert_response :success
    assert_select "p", text: "ナレッジを登録しました。"
    assert_select "h2", "VPNへの接続方法"
  end

  test "should sync chunks and embeddings when creating knowledge" do
    synced_knowledge_ids = []

    with_knowledge_embedding_sync(->(knowledge) {
      synced_knowledge_ids << knowledge.id
      true
    }) do
      post knowledges_url, params: {
        knowledge: {
          title: "VPNへの接続方法",
          content: "VPNクライアントを起動し、社員アカウントでログインしてください。",
          category: "IT"
        }
      }
    end

    assert_redirected_to knowledges_url
    assert_equal [ Knowledge.last.id ], synced_knowledge_ids
  end

  test "should keep create success when embedding sync fails" do
    with_knowledge_embedding_sync(false) do
      assert_difference("Knowledge.count", 1) do
        post knowledges_url, params: {
          knowledge: {
            title: "VPNへの接続方法",
            content: "VPNクライアントを起動してください。",
            category: "IT"
          }
        }
      end
    end

    assert_redirected_to knowledges_url
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

  test "should get edit" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    get edit_knowledge_url(knowledge)

    assert_response :success
    assert_select "h1", "ナレッジ編集"
    assert_select "form[action='#{knowledge_path(knowledge)}'][method='post']"
    assert_select "input[name='knowledge[title]'][value='経費精算の方法']"
    assert_select "input[name='knowledge[category]'][value='経費']"
    assert_select "textarea[name='knowledge[content]']", "経費精算はシステムから申請してください。"
  end

  test "should update knowledge" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    with_knowledge_embedding_sync(true) do
      patch knowledge_url(knowledge), params: {
        knowledge: {
          title: "経費精算の申請方法",
          content: "経費精算は経費精算システムから申請してください。",
          category: "経費・会計"
        }
      }
    end

    assert_redirected_to knowledge_url(knowledge)
    knowledge.reload
    assert_equal "経費精算の申請方法", knowledge.title
    assert_equal "経費精算は経費精算システムから申請してください。", knowledge.content
    assert_equal "経費・会計", knowledge.category

    follow_redirect!
    assert_response :success
    assert_select "p", text: "ナレッジを更新しました。"
    assert_select "h1", "経費精算の申請方法"
  end

  test "should resync chunks and embeddings when content changes" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )
    synced_knowledge_ids = []

    with_knowledge_embedding_sync(->(synced_knowledge) {
      synced_knowledge_ids << synced_knowledge.id
      true
    }) do
      patch knowledge_url(knowledge), params: {
        knowledge: {
          title: "経費精算の方法",
          content: "経費精算は経費精算システムから申請してください。",
          category: "経費"
        }
      }
    end

    assert_redirected_to knowledge_url(knowledge)
    assert_equal [ knowledge.id ], synced_knowledge_ids
  end

  test "should not resync when only title changes" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )
    synced_knowledge_ids = []

    with_knowledge_embedding_sync(->(synced_knowledge) {
      synced_knowledge_ids << synced_knowledge.id
      true
    }) do
      patch knowledge_url(knowledge), params: {
        knowledge: {
          title: "経費精算の申請方法",
          content: "経費精算はシステムから申請してください。",
          category: "経費"
        }
      }
    end

    assert_redirected_to knowledge_url(knowledge)
    assert_empty synced_knowledge_ids
  end

  test "should render edit with errors when update validation fails" do
    knowledge = Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    patch knowledge_url(knowledge), params: {
      knowledge: {
        title: "",
        content: "",
        category: ""
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", "ナレッジ編集"
    assert_select "p", text: "入力内容を確認してください。"
    assert_select "li", text: "Title can't be blank"
    assert_select "li", text: "Content can't be blank"
    assert_select "li", text: "Category can't be blank"

    knowledge.reload
    assert_equal "経費精算の方法", knowledge.title
    assert_equal "経費精算はシステムから申請してください。", knowledge.content
    assert_equal "経費", knowledge.category
  end

  test "should destroy knowledge and redirect to index" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動し、社員アカウントでログインしてください。",
      category: "IT"
    )
    KnowledgeChunk.create!(
      knowledge: knowledge,
      content: "VPNクライアントを起動してください。",
      position: 0
    )

    assert_difference("Knowledge.count", -1) do
      assert_difference("KnowledgeChunk.count", -1) do
        delete knowledge_url(knowledge)
      end
    end

    assert_redirected_to knowledges_url
    assert_not Knowledge.exists?(knowledge.id)

    follow_redirect!
    assert_response :success
    assert_select "p", text: "ナレッジを削除しました。"
    assert_select "h2", text: "VPNへの接続方法", count: 0
  end

  private

  def with_knowledge_embedding_sync(result)
    original = KnowledgeEmbeddingSync.method(:call)

    KnowledgeEmbeddingSync.define_singleton_method(:call) do |knowledge|
      result.respond_to?(:call) ? result.call(knowledge) : result
    end

    yield
  ensure
    KnowledgeEmbeddingSync.define_singleton_method(:call, original)
  end
end
