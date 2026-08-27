require "test_helper"

class KnowledgeChunkTest < ActiveSupport::TestCase
  test "valid with knowledge content and position" do
    chunk = build_knowledge_chunk

    assert chunk.valid?
  end

  test "invalid without knowledge" do
    chunk = build_knowledge_chunk(knowledge: nil)

    assert_not chunk.valid?
  end

  test "invalid without content" do
    chunk = build_knowledge_chunk(content: nil)

    assert_not chunk.valid?
  end

  test "invalid without position" do
    chunk = build_knowledge_chunk(position: nil)

    assert_not chunk.valid?
  end

  test "valid without embedding before embedding generation" do
    chunk = build_knowledge_chunk(embedding: nil, embedding_model: nil)

    assert chunk.valid?
  end

  private

  def build_knowledge_chunk(attributes = {})
    KnowledgeChunk.new({
      knowledge: Knowledge.new(
        title: "VPNへの接続方法",
        content: "VPNクライアントを起動してください。",
        category: "IT"
      ),
      content: "VPNクライアントを起動してください。",
      position: 0
    }.merge(attributes))
  end
end
