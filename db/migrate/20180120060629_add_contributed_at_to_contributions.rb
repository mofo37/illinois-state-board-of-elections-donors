class AddContributedAtToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :contributed_at, :datetime
  end
end
