class QuestionsController < ApplicationController
  RagContext = Data.define(:title, :category, :content)
  private_constant :RagContext

  rate_limit to: 10,
           within: 1.minute,
           only: :index,
           if: -> { params[:question].present? }

  def index
    @question = params[:question].to_s
    @retrieval_results = retrieve_results
    @knowledges = related_knowledges
    @ai_contexts = ai_contexts
    @ai_answer_result = generate_ai_answer
  end

  def new
  end

  private

  def retrieve_results
    return [] if @question.blank?

    KnowledgeRetriever.call(@question)
  rescue StandardError
    []
  end

  def related_knowledges
    @retrieval_results.map { |result| result.chunk.knowledge }.uniq
  end

  def ai_contexts
    @retrieval_results.map do |result|
      knowledge = result.chunk.knowledge
      RagContext.new(
        title: knowledge.title,
        category: knowledge.category,
        content: result.chunk.content
      )
    end
  end

  def generate_ai_answer
    if @question.blank?
      nil
    elsif @retrieval_results.empty?
      AiAnswerGenerator::Result.new(
        answer: nil,
        error_message: "関連するナレッジが見つからなかったため、AI回答は生成しませんでした"
      )
    else
      AiAnswerGenerator.call(question: @question, knowledges: @ai_contexts)
    end
  end
end
