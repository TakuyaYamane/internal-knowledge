class Knowledge < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :category, presence: true, length: { maximum: 100 }
end
