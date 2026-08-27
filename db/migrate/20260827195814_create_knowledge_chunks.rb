class CreateKnowledgeChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_chunks do |t|
      t.references :knowledge, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false
      t.vector :embedding, limit: 1536
      t.string :embedding_model

      t.timestamps
    end
  end
end
