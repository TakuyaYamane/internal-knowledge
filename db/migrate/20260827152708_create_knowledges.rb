class CreateKnowledges < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledges do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false

      t.timestamps
    end
  end
end
