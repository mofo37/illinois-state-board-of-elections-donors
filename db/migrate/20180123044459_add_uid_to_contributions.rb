class AddUidToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :uid, :string
  end
end
