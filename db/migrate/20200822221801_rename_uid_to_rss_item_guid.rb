class RenameUidToRssItemGuid < ActiveRecord::Migration[5.2]
  def change
    rename_column :contributions, :uid, :rss_item_guid
  end
end