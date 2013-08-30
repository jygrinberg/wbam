class CreateBeanstalkFetchers < ActiveRecord::Migration
  def change
    create_table :beanstalk_fetchers do |t|
      t.datetime :started_fetch_at
      t.datetime :completed_fetch_at
      t.integer :repeat_frequency_sec

      t.timestamps
    end
  end
end
