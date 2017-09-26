class CreateGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :groups do |t|
      t.string :status
      t.string :groupId      
      t.timestamps
    end
  end
end
