class Knowledge < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :category, presence: true, length: { maximum: 100 }

  def self.search(query)
    return order(created_at: :desc) if query.blank?

    search_query = "%#{sanitize_sql_like(query)}%"

    where(
      "title ILIKE :query OR content ILIKE :query OR category ILIKE :query",
      query: search_query
    ).order(created_at: :desc)
  end
end
