class CreateDatapoints < ActiveRecord::Migration
  def change
    create_table :datapoints do |t|
      t.datetime :timestamp
      t.float :value

      t.integer :metric_id
      t.integer :instance_id
      t.integer :loadBalancer_id

      t.timestamps
    end
  end
end
