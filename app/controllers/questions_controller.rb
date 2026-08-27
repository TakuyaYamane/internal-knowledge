class QuestionsController < ApplicationController
  def index
    @question = params[:question].to_s
    @knowledges = @question.blank? ? Knowledge.none : Knowledge.search(@question)
  end

  def new
  end
end
