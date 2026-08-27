require "test_helper"

class KnowledgeChunkEmbeddingGeneratorTest < ActiveSupport::TestCase
  test "saves embedding when generation succeeds" do
    chunk = create_knowledge_chunk
    embedding = sample_embedding(0.1)

    result = with_embedding_generator(embedding) do
      KnowledgeChunkEmbeddingGenerator.call(chunk)
    end

    assert_equal chunk, result
    assert_equal embedding, chunk.reload.embedding
  end

  test "saves embedding model when generation succeeds" do
    chunk = create_knowledge_chunk

    result = with_embedding_model("text-embedding-3-small") do
      with_embedding_generator(sample_embedding(0.1)) do
        KnowledgeChunkEmbeddingGenerator.call(chunk)
      end
    end

    assert_equal chunk, result
    assert_equal "text-embedding-3-small", chunk.reload.embedding_model
  end

  test "does not update chunk when embedding generation fails" do
    chunk = create_knowledge_chunk(embedding: sample_embedding(0.1), embedding_model: "existing-model")

    result = with_embedding_generator(nil) do
      KnowledgeChunkEmbeddingGenerator.call(chunk)
    end

    assert_nil result
    chunk.reload
    assert_equal sample_embedding(0.1), chunk.embedding
    assert_equal "existing-model", chunk.embedding_model
  end

  test "regenerates existing embedding" do
    chunk = create_knowledge_chunk(embedding: sample_embedding(0.1), embedding_model: "old-model")
    new_embedding = sample_embedding(0.2)

    result = with_embedding_model("new-model") do
      with_embedding_generator(new_embedding) do
        KnowledgeChunkEmbeddingGenerator.call(chunk)
      end
    end

    assert_equal chunk, result
    chunk.reload
    assert_equal new_embedding, chunk.embedding
    assert_equal "new-model", chunk.embedding_model
  end

  test "returns nil when saving fails" do
    chunk = create_knowledge_chunk
    original_update = chunk.method(:update!)
    chunk.define_singleton_method(:update!) { |**| raise ActiveRecord::RecordInvalid }

    begin
      result = with_embedding_generator(sample_embedding(0.1)) do
        KnowledgeChunkEmbeddingGenerator.call(chunk)
      end
    ensure
      chunk.define_singleton_method(:update!, original_update)
    end

    assert_nil result
    chunk.reload
    assert_nil chunk.embedding
    assert_nil chunk.embedding_model
  end

  private

  def create_knowledge_chunk(attributes = {})
    knowledge = Knowledge.create!(
      title: "VPNへの接続方法",
      content: "VPNクライアントを起動してください。",
      category: "IT"
    )

    KnowledgeChunk.create!({
      knowledge: knowledge,
      content: "VPNクライアントを起動してください。",
      position: 0
    }.merge(attributes))
  end

  def sample_embedding(value)
    Array.new(1_536, value)
  end

  def with_embedding_generator(result)
    original = EmbeddingGenerator.method(:call)
    EmbeddingGenerator.define_singleton_method(:call) { |*| result }

    yield
  ensure
    EmbeddingGenerator.define_singleton_method(:call, original)
  end

  def with_embedding_model(model)
    previous_model = ENV["OPENAI_EMBEDDING_MODEL"]
    ENV["OPENAI_EMBEDDING_MODEL"] = model

    yield
  ensure
    ENV["OPENAI_EMBEDDING_MODEL"] = previous_model
  end
end
