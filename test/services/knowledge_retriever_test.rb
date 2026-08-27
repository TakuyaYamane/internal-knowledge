require "test_helper"

class KnowledgeRetrieverTest < ActiveSupport::TestCase
  test "generates question embedding" do
    captured_question = nil
    create_knowledge_chunk(embedding: embedding_for(1.0, 0.0), content: "VPNの説明")

    with_embedding_generator(->(question) {
      captured_question = question
      embedding_for(1.0, 0.0)
    }) do
      KnowledgeRetriever.call("VPNについて教えて")
    end

    assert_equal "VPNについて教えて", captured_question
  end

  test "returns nearest chunk first" do
    far_chunk = create_knowledge_chunk(embedding: embedding_for(0.0, 1.0), content: "経費の説明")
    near_chunk = create_knowledge_chunk(embedding: embedding_for(1.0, 0.0), content: "VPNの説明")

    results = with_embedding_generator(embedding_for(1.0, 0.0)) do
      KnowledgeRetriever.call("VPN", max_distance: 1.1)
    end

    assert_equal near_chunk, results.first.chunk
    assert_includes results.map(&:chunk), far_chunk
  end

  test "excludes chunks without embedding" do
    create_knowledge_chunk(embedding: nil, content: "未生成のChunk")
    embedded_chunk = create_knowledge_chunk(embedding: embedding_for(1.0, 0.0), content: "生成済みChunk")

    results = with_embedding_generator(embedding_for(1.0, 0.0)) do
      KnowledgeRetriever.call("VPN")
    end

    assert_equal [ embedded_chunk ], results.map(&:chunk)
  end

  test "limits results by top k" do
    3.times do |index|
      create_knowledge_chunk(embedding: embedding_for(1.0, index / 10.0), content: "Chunk #{index}")
    end

    results = with_embedding_generator(embedding_for(1.0, 0.0)) do
      KnowledgeRetriever.call("VPN", top_k: 2)
    end

    assert_equal 2, results.size
  end

  test "filters distant chunks by threshold" do
    near_chunk = create_knowledge_chunk(embedding: embedding_for(1.0, 0.0), content: "近いChunk")
    create_knowledge_chunk(embedding: embedding_for(0.0, 1.0), content: "遠いChunk")

    results = with_embedding_generator(embedding_for(1.0, 0.0)) do
      KnowledgeRetriever.call("VPN", max_distance: 0.2)
    end

    assert_equal [ near_chunk ], results.map(&:chunk)
    assert results.all? { |result| result.distance <= 0.2 }
  end

  test "returns empty results when embedding generation fails" do
    create_knowledge_chunk(embedding: embedding_for(1.0, 0.0), content: "VPNの説明")

    results = with_embedding_generator(nil) do
      KnowledgeRetriever.call("VPN")
    end

    assert_empty results
  end

  private

  def create_knowledge_chunk(attributes = {})
    knowledge = Knowledge.create!(
      title: "社内ナレッジ",
      content: "本文です。",
      category: "一般"
    )

    KnowledgeChunk.create!({
      knowledge: knowledge,
      content: "本文です。",
      position: 0
    }.merge(attributes))
  end

  def embedding_for(first, second)
    [ first, second ] + Array.new(1_534, 0.0)
  end

  def with_embedding_generator(result)
    original = EmbeddingGenerator.method(:call)

    EmbeddingGenerator.define_singleton_method(:call) do |question|
      result.respond_to?(:call) ? result.call(question) : result
    end

    yield
  ensure
    EmbeddingGenerator.define_singleton_method(:call, original)
  end
end
