class AddDatetimePiecesToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :year,   :string
    add_column :contributions, :month,  :string
    add_column :contributions, :day,    :string
    add_column :contributions, :hour,   :string
    add_column :contributions, :minute, :string
    add_column :contributions, :second, :string
  end
end