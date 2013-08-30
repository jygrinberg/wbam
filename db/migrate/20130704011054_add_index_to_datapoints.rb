class AddIndexToDatapoints < ActiveRecord::Migration
  def change
  	add_index :datapoints, :timestamp
  	add_index :datapoints, :metric_id
  end
end
