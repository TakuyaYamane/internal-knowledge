class KnowledgeChunker
  MAX_CHUNK_SIZE = 700
  OVERLAP_SIZE = 120
  SENTENCE_BOUNDARY = /(?<=[。！？])/
  HARD_SPLIT_BOUNDARY = MAX_CHUNK_SIZE - OVERLAP_SIZE

  def self.call(knowledge)
    new(knowledge).call
  end

  def initialize(knowledge)
    @knowledge = knowledge
  end

  def call
    chunks = split_content

    KnowledgeChunk.transaction do
      knowledge.knowledge_chunks.destroy_all

      chunks.each_with_index.map do |chunk, position|
        knowledge.knowledge_chunks.create!(
          content: chunk,
          position: position
        )
      end
    end
  end

  private

  attr_reader :knowledge

  def split_content
    units.each_with_object([]) do |unit, chunks|
      add_unit(chunks, unit)
    end
  end

  def units
    knowledge.content.to_s
      .split(/(\n{2,}|\n|#{SENTENCE_BOUNDARY})/)
      .each_slice(2)
      .map(&:join)
      .flat_map { |unit| split_long_unit(unit) }
      .map(&:strip)
      .reject(&:blank?)
  end

  def split_long_unit(unit)
    return [ unit ] if unit.length <= MAX_CHUNK_SIZE

    unit.scan(/.{1,#{HARD_SPLIT_BOUNDARY}}/m)
  end

  def add_unit(chunks, unit)
    if chunks.empty?
      chunks << unit
    elsif chunks.last.length + unit.length <= MAX_CHUNK_SIZE
      chunks[-1] = [ chunks.last, unit ].join
    else
      chunks << [ overlap_from(chunks.last), unit ].reject(&:blank?).join
    end
  end

  def overlap_from(chunk)
    chunk.last(OVERLAP_SIZE)
  end
end
