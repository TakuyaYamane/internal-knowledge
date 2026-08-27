namespace :knowledge_embeddings do
  desc "Backfill KnowledgeChunks and embeddings for existing Knowledges"
  task backfill: :environment do
    result = KnowledgeEmbeddingBackfill.call(output: $stdout)

    puts "Processed Knowledges: #{result.processed_count}"
    puts "Succeeded Knowledges: #{result.succeeded_count}"
    puts "Failed Knowledges: #{result.failed_count}"
  end
end
