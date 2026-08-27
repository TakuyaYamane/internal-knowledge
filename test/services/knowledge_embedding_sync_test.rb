require "test_helper"

class KnowledgeEmbeddingSyncTest < ActiveSupport::TestCase
  test "chunks knowledge and generates embeddings for each chunk" do
    knowledge = create_knowledge
    first_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "最初のChunk", position: 0)
    second_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "次のChunk", position: 1)
    embedded_chunk_ids = []

    result = with_chunker([ first_chunk, second_chunk ]) do
      with_chunk_embedding_generator(->(chunk) {
        embedded_chunk_ids << chunk.id
        chunk
      }) do
        KnowledgeEmbeddingSync.call(knowledge)
      end
    end

    assert result
    assert_equal [ first_chunk.id, second_chunk.id ], embedded_chunk_ids
  end

  test "returns false when embedding generation fails" do
    knowledge = create_knowledge
    chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "Chunk", position: 0)

    result = with_chunker([ chunk ]) do
      with_chunk_embedding_generator(nil) do
        KnowledgeEmbeddingSync.call(knowledge)
      end
    end

    assert_not result
  end

  test "returns false when chunking raises error" do
    knowledge = create_knowledge

    result = with_chunker(->(*) { raise "chunk error" }) do
      KnowledgeEmbeddingSync.call(knowledge)
    end

    assert_not result
  end

  private

  def create_knowledge
    Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )
  end

  def with_chunker(result)
    original = KnowledgeChunker.method(:call)

    KnowledgeChunker.define_singleton_method(:call) do |knowledge|
      result.respond_to?(:call) ? result.call(knowledge) : result
    end

    yield
  ensure
    KnowledgeChunker.define_singleton_method(:call, original)
  end

  def with_chunk_embedding_generator(result)
    original = KnowledgeChunkEmbeddingGenerator.method(:call)

    KnowledgeChunkEmbeddingGenerator.define_singleton_method(:call) do |chunk|
      result.respond_to?(:call) ? result.call(chunk) : result
    end

    yield
  ensure
    KnowledgeChunkEmbeddingGenerator.define_singleton_method(:call, original)
  end
end
