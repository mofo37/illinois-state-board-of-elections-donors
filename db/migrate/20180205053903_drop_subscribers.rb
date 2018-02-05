class DropSubscribers < ActiveRecord::Migration[5.1]
  def up
    drop_table :subscribers
  end

  def down
    create_table :subscribers do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
