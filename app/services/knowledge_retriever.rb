class KnowledgeRetriever
  DEFAULT_TOP_K = 5
  DEFAULT_MAX_DISTANCE = 0.45
  Result = Data.define(:chunk, :distance)

  def self.call(question, top_k: DEFAULT_TOP_K, max_distance: DEFAULT_MAX_DISTANCE)
    new(question, top_k:, max_distance:).call
  end

  def initialize(question, top_k:, max_distance:)
    @question = question.to_s
    @top_k = top_k
    @max_distance = max_distance
  end

  def call
    question_embedding = EmbeddingGenerator.call(question)
    return [] if question_embedding.blank?

    nearest_chunks(question_embedding).map do |chunk|
      Result.new(chunk: chunk, distance: chunk.neighbor_distance)
    end
  end

  private

  attr_reader :question, :top_k, :max_distance

  def nearest_chunks(question_embedding)
    KnowledgeChunk
      .where.not(embedding: nil)
      .nearest_neighbors(:embedding, question_embedding, distance: "cosine", threshold: max_distance)
      .first(top_k)
  end
end
