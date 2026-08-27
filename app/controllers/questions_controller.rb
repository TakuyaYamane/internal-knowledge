class QuestionsController < ApplicationController
  def index
    @question = params[:question].to_s
    @knowledges = @question.blank? ? Knowledge.none : Knowledge.search(@question)
    @ai_answer_result = generate_ai_answer
  end

  def new
  end

  private

  def generate_ai_answer
    if @question.blank?
      nil
    elsif @knowledges.empty?
      AiAnswerGenerator::Result.new(
        answer: nil,
        error_message: "関連するナレッジが見つからなかったため、AI回答は生成しませんでした"
      )
    else
      AiAnswerGenerator.call(question: @question, knowledges: @knowledges)
    end
  end
end
