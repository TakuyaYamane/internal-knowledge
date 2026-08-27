class KnowledgeChunkEmbeddingGenerator
  def self.call(knowledge_chunk)
    new(knowledge_chunk).call
  end

  def initialize(knowledge_chunk)
    @knowledge_chunk = knowledge_chunk
  end

  def call
    embedding = EmbeddingGenerator.call(knowledge_chunk.content)
    return nil if embedding.blank?

    knowledge_chunk.update!(
      embedding: embedding,
      embedding_model: embedding_model
    )

    knowledge_chunk
  rescue ActiveRecord::ActiveRecordError
    nil
  end

  private

  attr_reader :knowledge_chunk

  def embedding_model
    ENV.fetch("OPENAI_EMBEDDING_MODEL", EmbeddingGenerator::DEFAULT_MODEL)
  end
end
