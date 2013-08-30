class AddFetchCountToDataFetcher < ActiveRecord::Migration
  def change
    add_column :data_fetchers, :fetch_count, :integer
  end
end
