class KnowledgeChunk < ApplicationRecord
  belongs_to :knowledge

  validates :content, presence: true
  validates :position, presence: true
end
