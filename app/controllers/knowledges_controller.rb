class KnowledgesController < ApplicationController
  def index
    @knowledges = Knowledge.order(created_at: :desc)
  end

  def show
    @knowledge = Knowledge.find(params[:id])
  end

  def edit
    @knowledge = Knowledge.find(params[:id])
  end

  def new
    @knowledge = Knowledge.new
  end

  def create
    @knowledge = Knowledge.new(knowledge_params)

    if @knowledge.save
      redirect_to knowledges_path, notice: "ナレッジを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @knowledge = Knowledge.find(params[:id])

    if @knowledge.update(knowledge_params)
      redirect_to knowledge_path(@knowledge), notice: "ナレッジを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge = Knowledge.find(params[:id])
    @knowledge.destroy

    redirect_to knowledges_path, notice: "ナレッジを削除しました。"
  end

  private

  def knowledge_params
    params.require(:knowledge).permit(:title, :content, :category)
  end
end
