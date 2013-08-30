class AddFetchCountToBeanstalkFetcher < ActiveRecord::Migration
  def change
    add_column :beanstalk_fetchers, :fetch_count, :integer
  end
end
