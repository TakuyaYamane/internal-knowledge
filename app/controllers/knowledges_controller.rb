class KnowledgesController < ApplicationController
 allow_unauthenticated_access only: %i[index show]

 def index
    @query = params[:q]
    @knowledges = Knowledge.search(@query)
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
      sync_knowledge_embedding(@knowledge)
      redirect_to knowledges_path, notice: "ナレッジを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @knowledge = Knowledge.find(params[:id])

    if @knowledge.update(knowledge_params)
      sync_knowledge_embedding(@knowledge) if @knowledge.saved_change_to_content?
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

  def sync_knowledge_embedding(knowledge)
    KnowledgeEmbeddingSync.call(knowledge)
  end
end
