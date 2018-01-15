class CreateContributions < ActiveRecord::Migration[5.1]
  def change
    create_table :contributions do |t|
      t.string :form
      t.string :contributed_by
      t.string :amount
      t.string :received_by

      t.timestamps
    end
  end
end
