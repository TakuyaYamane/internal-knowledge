class KnowledgesController < ApplicationController
  def index
    @knowledges = Knowledge.order(created_at: :desc)
  end
end
