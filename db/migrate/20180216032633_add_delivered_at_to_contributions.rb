class AddDeliveredAtToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :delivered_at, :datetime
  end
end
