class DropUnusedFieldsOnContributions < ActiveRecord::Migration[5.1]
  def change
    remove_column :contributions, :payee, :string
    remove_column :contributions, :candidate_name, :string
    remove_column :contributions, :purpose, :string
    remove_column :contributions, :payor, :string
    remove_column :contributions, :delivered_at, :datetime
  end
end
