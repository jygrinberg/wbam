class CreateDataFetchers < ActiveRecord::Migration
    def change
        create_table :data_fetchers do |t|
            t.datetime :started_fetch_at
            t.datetime :completed_fetch_at
            t.integer :start_min_ago
            t.integer :end_min_ago
            t.integer :repeat_frequency_sec
            t.string :intervals
            t.string :metrics
            t.string :periods

            t.timestamps
        end
    end
end
