class CreatePhrases < ActiveRecord::Migration[5.1]
  def change
    create_table :phrases do |t|
      t.string :group_id
      t.string :if
      t.string :then

      t.timestamps
    end
  end
end
