class Knowledge < ApplicationRecord
  has_many :knowledge_chunks, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :category, presence: true, length: { maximum: 100 }

  def self.search(query)
    return order(created_at: :desc) if query.blank?

    terms = search_terms(query)

    return none.order(created_at: :desc) if terms.empty?

    table = arel_table

    condition = terms.map do |term|
      pattern = "%#{sanitize_sql_like(term)}%"

      table[:title].matches(pattern, nil, false)
        .or(table[:content].matches(pattern, nil, false))
        .or(table[:category].matches(pattern, nil, false))
    end.reduce(&:or)

    where(condition).order(created_at: :desc)
  end

  def self.search_terms(query)
    normalized_query = query.to_s.tr("　", " ")

    stop_phrases.each do |phrase|
      normalized_query = normalized_query.gsub(phrase, " ")
    end

    normalized_query
      .split(/[[:space:]、。，．・！？!?\(\)（）「」『』【】\[\]{}<>《》:：;；,\/\\]+/)
      .map(&:strip)
      .reject { |term| term.length < 2 || stop_words.include?(term) }
      .uniq
  end

  def self.stop_phrases
    %w[
      について
      に関して
      に関する
      してください
      して下さい
      教えてください
      教えて下さい
      教えて
      ください
      下さい
      ですか
      ますか
      とは
      への
      から
      まで
      には
      では
      ても
      でも
      の
      を
      は
      が
      に
      へ
      と
      で
      や
    ]
  end

  def self.stop_words
    %w[
      方法
      手順
      申請
      確認
      対応
      どこ
      なに
      何
    ]
  end
end
