class KnowledgeEmbeddingSync
  def self.call(knowledge)
    new(knowledge).call
  end

  def initialize(knowledge)
    @knowledge = knowledge
  end

  def call
    chunks = KnowledgeChunker.call(knowledge)
    chunks.all? { |chunk| KnowledgeChunkEmbeddingGenerator.call(chunk).present? }
  rescue StandardError => error
    Rails.logger.warn("Knowledge embedding sync failed knowledge_id=#{knowledge.id} error=#{error.class.name}")
    false
  end

  private

  attr_reader :knowledge
end
