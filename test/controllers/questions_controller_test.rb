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
    chunk = create_chunk(knowledge, content: "社外から社内システムにアクセスする場合はVPNを利用してください。")

    with_knowledge_retriever([ retrieval_result(chunk) ]) do
      with_ai_answer_generator(ai_answer("VPNを利用してください。")) do
        get questions_url(question: "VPN")
      end
    end

    assert_response :success
    assert_select "h1", "ナレッジに質問"
    assert_select "textarea[name='question']", "VPN"
    assert_select "h2", "関連するナレッジ"
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
    assert_select "p", text: "カテゴリ: IT"
  end

  test "should display ai answer when matching knowledges exist" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )
    chunk = create_chunk(knowledge, content: "VPNを利用してください。")

    with_knowledge_retriever([ retrieval_result(chunk) ]) do
      with_ai_answer_generator(ai_answer("VPNを利用してください。")) do
        get questions_url(question: "VPN")
      end
    end

    assert_response :success
    assert_select "h2", "AI回答"
    assert_select "p", text: "VPNを利用してください。"
  end

  test "should use rag result for natural language question" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )
    chunk = create_chunk(knowledge, content: "社外から社内システムにアクセスする場合はVPNを利用してください。")
    captured_question = nil

    with_knowledge_retriever(->(question) {
      captured_question = question
      [ retrieval_result(chunk, distance: 0.4029) ]
    }) do
      with_ai_answer_generator(ai_answer("VPNを利用してください。")) do
        get questions_url(question: "社外から会社のシステムに入りたい")
      end
    end

    assert_response :success
    assert_equal "社外から会社のシステムに入りたい", captured_question
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
  end

  test "should not display unmatched knowledges" do
    Knowledge.create!(
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    )

    with_knowledge_retriever([]) do
      get questions_url(question: "VPN")
    end

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

    with_knowledge_retriever([]) do
      with_ai_answer_generator(->(*) { raise "should not be called" }) do
        get questions_url(question: "VPN")
      end
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
    chunk = create_chunk(knowledge)
    result = AiAnswerGenerator::Result.new(
      answer: nil,
      error_message: "AI回答の生成に失敗しました。関連ナレッジを確認してください。"
    )

    with_knowledge_retriever([ retrieval_result(chunk) ]) do
      with_ai_answer_generator(result) do
        get questions_url(question: "VPN")
      end
    end

    assert_response :success
    assert_select "p", text: "AI回答の生成に失敗しました。関連ナレッジを確認してください。"
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
  end

  test "should not duplicate same knowledge from multiple chunks" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "社外から社内システムにアクセスする場合はVPNを利用してください。",
      category: "IT"
    )
    first_chunk = create_chunk(knowledge, content: "社外から利用する場合はVPNを使います。", position: 0)
    second_chunk = create_chunk(knowledge, content: "VPNクライアントでログインします。", position: 1)

    with_knowledge_retriever([ retrieval_result(first_chunk), retrieval_result(second_chunk) ]) do
      with_ai_answer_generator(ai_answer("VPNを利用してください。")) do
        get questions_url(question: "社外から会社のシステムに入りたい")
      end
    end

    assert_response :success
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", count: 1
    assert_select "h3 a[href='#{knowledge_path(knowledge)}']", "VPNへの接続方法"
  end

  test "should pass chunk contexts to ai answer generator" do
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "Knowledge全体本文です。",
      category: "IT"
    )
    chunk = create_chunk(knowledge, content: "Chunk本文です。")
    captured_contexts = nil

    with_knowledge_retriever([ retrieval_result(chunk) ]) do
      with_ai_answer_generator(->(**arguments) {
        captured_contexts = arguments[:knowledges]
        ai_answer("Chunkを根拠に回答します。")
      }) do
        get questions_url(question: "社外から会社のシステムに入りたい")
      end
    end

    assert_response :success
    assert_equal "VPNへの接続方法", captured_contexts.first.title
    assert_equal "IT", captured_contexts.first.category
    assert_equal "Chunk本文です。", captured_contexts.first.content
  end

  test "should handle retriever failure safely" do
    with_knowledge_retriever(->(*) { raise "retriever error" }) do
      with_ai_answer_generator(->(*) { raise "should not be called" }) do
        get questions_url(question: "社外から会社のシステムに入りたい")
      end
    end

    assert_response :success
    assert_select "p", text: "関連するナレッジが見つからなかったため、AI回答は生成しませんでした"
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

  private

  def create_chunk(knowledge, content: "社外から社内システムにアクセスする場合はVPNを利用してください。", position: 0)
    KnowledgeChunk.create!(
      knowledge: knowledge,
      content: content,
      position: position
    )
  end

  def retrieval_result(chunk, distance: 0.12)
    KnowledgeRetriever::Result.new(chunk: chunk, distance: distance)
  end

  def ai_answer(answer)
    AiAnswerGenerator::Result.new(answer: answer, error_message: nil)
  end

  def with_knowledge_retriever(result)
    original = KnowledgeRetriever.method(:call)

    KnowledgeRetriever.define_singleton_method(:call) do |question|
      result.respond_to?(:call) ? result.call(question) : result
    end

    yield
  ensure
    KnowledgeRetriever.define_singleton_method(:call, original)
  end

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
