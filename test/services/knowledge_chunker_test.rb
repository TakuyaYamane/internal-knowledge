require "test_helper"

class KnowledgeChunkerTest < ActiveSupport::TestCase
  test "creates one chunk for short content" do
    knowledge = create_knowledge(content: "VPNクライアントを起動してください。")

    chunks = KnowledgeChunker.call(knowledge)

    assert_equal 1, chunks.size
    assert_equal "VPNクライアントを起動してください。", chunks.first.content
  end

  test "creates multiple chunks for long content" do
    knowledge = create_knowledge(content: long_sentences)

    chunks = KnowledgeChunker.call(knowledge)

    assert_operator chunks.size, :>, 1
  end

  test "sets positions from zero" do
    knowledge = create_knowledge(content: long_sentences)

    chunks = KnowledgeChunker.call(knowledge)

    assert_equal (0...chunks.size).to_a, chunks.map(&:position)
  end

  test "keeps chunks in source order" do
    knowledge = create_knowledge(content: "#{"最初の説明。" * 40}\n#{"次の説明。" * 40}\n#{"最後の説明。" * 40}")

    KnowledgeChunker.call(knowledge)

    assert_equal 0, knowledge.knowledge_chunks.order(:position).first.position
    assert_includes knowledge.knowledge_chunks.order(:position).first.content, "最初の説明。"
    assert_includes knowledge.knowledge_chunks.order(:position).last.content, "最後の説明。"
  end

  test "adds overlap between chunks" do
    knowledge = create_knowledge(content: long_sentences)

    chunks = KnowledgeChunker.call(knowledge)

    first_overlap = chunks.first.content.last(KnowledgeChunker::OVERLAP_SIZE)
    assert chunks.second.content.start_with?(first_overlap)
  end

  test "does not create blank chunks" do
    knowledge = create_knowledge(content: "\n\nVPNクライアントを起動してください。\n\n\n社員アカウントでログインしてください。\n")

    chunks = KnowledgeChunker.call(knowledge)

    assert chunks.all? { |chunk| chunk.content.present? }
  end

  test "splits a very long sentence" do
    knowledge = create_knowledge(content: "あ" * 1_600)

    chunks = KnowledgeChunker.call(knowledge)

    assert_operator chunks.size, :>, 1
    assert chunks.all? { |chunk| chunk.content.length <= KnowledgeChunker::MAX_CHUNK_SIZE }
  end

  test "prefers Japanese sentence boundary" do
    content = ("前半の説明。" * 55) + ("後半の説明。" * 55)
    knowledge = create_knowledge(content: content)

    chunks = KnowledgeChunker.call(knowledge)

    assert chunks.first.content.end_with?("。")
  end

  test "does not duplicate chunks when rerun" do
    knowledge = create_knowledge(content: long_sentences)

    first_chunks = KnowledgeChunker.call(knowledge)
    second_chunks = KnowledgeChunker.call(knowledge)

    assert_equal second_chunks.size, knowledge.knowledge_chunks.count
    assert_equal first_chunks.size, second_chunks.size
  end

  test "replaces old chunks when rerun" do
    knowledge = create_knowledge(content: "古い本文です。")
    old_chunk = KnowledgeChunker.call(knowledge).first

    knowledge.update!(content: "新しい本文です。")
    new_chunk = KnowledgeChunker.call(knowledge).first

    assert_not KnowledgeChunk.exists?(old_chunk.id)
    assert_equal "新しい本文です。", new_chunk.content
  end

  test "rolls back when saving a chunk fails" do
    knowledge = create_knowledge(content: "既存本文です。")
    original_chunk = KnowledgeChunker.call(knowledge).first
    knowledge.update!(content: "新しい本文です。")

    chunks_association = knowledge.knowledge_chunks
    original_create = chunks_association.method(:create!)
    chunks_association.define_singleton_method(:create!) { |*| raise ActiveRecord::RecordInvalid }

    begin
      assert_raises(ActiveRecord::RecordInvalid) do
        KnowledgeChunker.call(knowledge)
      end
    ensure
      chunks_association.define_singleton_method(:create!, original_create)
    end

    assert KnowledgeChunk.exists?(original_chunk.id)
    assert_equal [ "既存本文です。" ], knowledge.knowledge_chunks.reload.order(:position).pluck(:content)
  end

  test "leaves embedding unset" do
    knowledge = create_knowledge(content: "VPNクライアントを起動してください。")

    chunk = KnowledgeChunker.call(knowledge).first

    assert_nil chunk.embedding
  end

  test "leaves embedding model unset" do
    knowledge = create_knowledge(content: "VPNクライアントを起動してください。")

    chunk = KnowledgeChunker.call(knowledge).first

    assert_nil chunk.embedding_model
  end

  private

  def create_knowledge(attributes = {})
    Knowledge.create!({
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    }.merge(attributes))
  end

  def long_sentences
    "VPNクライアントを起動してください。" * 80
  end
end
