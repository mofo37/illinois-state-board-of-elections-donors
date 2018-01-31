class AddB1FieldsToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :payee, :string
    add_column :contributions, :candidate_name, :string
    add_column :contributions, :purpose, :string
    add_column :contributions, :payor, :string
  end
end
