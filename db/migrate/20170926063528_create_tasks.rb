class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :name
      t.date :limit
      t.string :group_id

      t.timestamps
    end
  end
end
