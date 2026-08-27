class KnowledgeEmbeddingBackfill
  Result = Data.define(:processed_count, :succeeded_count, :failed_count)

  def self.call(output: nil)
    new(output: output).call
  end

  def initialize(output:)
    @output = output
    @processed_count = 0
    @succeeded_count = 0
    @failed_count = 0
  end

  def call
    Knowledge.find_each do |knowledge|
      process_knowledge(knowledge)
    end

    Result.new(
      processed_count: processed_count,
      succeeded_count: succeeded_count,
      failed_count: failed_count
    )
  end

  private

  attr_reader :output, :processed_count, :succeeded_count, :failed_count

  def process_knowledge(knowledge)
    @processed_count += 1
    output&.puts "Processing Knowledge ID=#{knowledge.id}"

    chunks = KnowledgeChunker.call(knowledge)
    failed_chunks = chunks.count { |chunk| KnowledgeChunkEmbeddingGenerator.call(chunk).nil? }

    if failed_chunks.zero?
      @succeeded_count += 1
      output&.puts "Succeeded Knowledge ID=#{knowledge.id}"
    else
      @failed_count += 1
      output&.puts "Failed Knowledge ID=#{knowledge.id} failed_chunks=#{failed_chunks}"
    end
  rescue StandardError => error
    @failed_count += 1
    output&.puts "Failed Knowledge ID=#{knowledge.id} error=#{error.class.name}"
  end
end
