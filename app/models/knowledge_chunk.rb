class KnowledgeChunk < ApplicationRecord
  belongs_to :knowledge
  has_neighbors :embedding

  validates :content, presence: true
  validates :position, presence: true
end
