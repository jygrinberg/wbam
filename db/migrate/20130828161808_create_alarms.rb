class CreateAlarms < ActiveRecord::Migration
  def change
    create_table :alarms do |t|
      t.integer :metric_id
      t.integer :period
      t.float :threshold
      t.string :relation
      t.integer :min_length_sec
      t.float :priority

      t.timestamps
    end
  end
end
