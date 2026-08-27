require "test_helper"

class KnowledgeEmbeddingBackfillTest < ActiveSupport::TestCase
  test "processes multiple knowledges" do
    create_knowledge
    create_knowledge

    result = with_embedding_generator_success do
      KnowledgeEmbeddingBackfill.call
    end

    assert_equal 2, result.processed_count
    assert_equal 2, result.succeeded_count
    assert_equal 0, result.failed_count
  end

  test "calls chunker for each knowledge" do
    first = create_knowledge
    second = create_knowledge
    called_ids = []

    result = with_chunker(->(knowledge) {
      called_ids << knowledge.id
      create_chunk_for(knowledge)
    }) do
      with_chunk_embedding_generator(->(chunk) { chunk }) do
        KnowledgeEmbeddingBackfill.call
      end
    end

    assert_equal 2, result.succeeded_count
    assert_equal [ first.id, second.id ], called_ids.sort
  end

  test "calls embedding generator for each chunk" do
    knowledge = create_knowledge
    first_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "最初のChunk", position: 0)
    second_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "次のChunk", position: 1)
    called_chunk_ids = []

    result = with_chunker([ first_chunk, second_chunk ]) do
      with_chunk_embedding_generator(->(chunk) {
        called_chunk_ids << chunk.id
        chunk
      }) do
        KnowledgeEmbeddingBackfill.call
      end
    end

    assert_equal 1, result.succeeded_count
    assert_equal [ first_chunk.id, second_chunk.id ], called_chunk_ids
  end

  test "continues when one knowledge fails" do
    failing = create_knowledge
    succeeding = create_knowledge

    result = with_chunker(->(knowledge) {
      raise "chunk error" if knowledge.id == failing.id

      create_chunk_for(knowledge)
    }) do
      with_chunk_embedding_generator(->(chunk) { chunk }) do
        KnowledgeEmbeddingBackfill.call
      end
    end

    assert_equal 2, result.processed_count
    assert_equal 1, result.succeeded_count
    assert_equal 1, result.failed_count
    assert KnowledgeChunk.exists?(knowledge: succeeding)
  end

  test "counts knowledge as failed when a chunk embedding fails" do
    knowledge = create_knowledge
    first_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "最初のChunk", position: 0)
    second_chunk = KnowledgeChunk.create!(knowledge: knowledge, content: "次のChunk", position: 1)

    result = with_chunker([ first_chunk, second_chunk ]) do
      with_chunk_embedding_generator(->(chunk) { chunk == first_chunk ? chunk : nil }) do
        KnowledgeEmbeddingBackfill.call
      end
    end

    assert_equal 1, result.processed_count
    assert_equal 0, result.succeeded_count
    assert_equal 1, result.failed_count
  end

  test "returns success and failure counts" do
    create_knowledge
    create_knowledge

    result = with_chunker(->(knowledge) { create_chunk_for(knowledge) }) do
      with_chunk_embedding_generator(->(chunk) { chunk.position.zero? ? chunk : nil }) do
        KnowledgeEmbeddingBackfill.call
      end
    end

    assert_equal 2, result.processed_count
    assert_equal 2, result.succeeded_count
    assert_equal 0, result.failed_count
  end

  private

  def create_knowledge
    Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )
  end

  def create_chunk_for(knowledge)
    [
      KnowledgeChunk.create!(
        knowledge: knowledge,
        content: knowledge.content,
        position: 0
      )
    ]
  end

  def with_embedding_generator_success
    with_chunk_embedding_generator(->(chunk) {
      chunk.update!(
        embedding: Array.new(1_536, 0.1),
        embedding_model: "text-embedding-3-small"
      )
      chunk
    }) do
      yield
    end
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
