class CreateMetrics < ActiveRecord::Migration
  def change
    create_table :metrics do |t|
      t.string :metric_name
      t.string :namespace
      t.string :data_type
      t.string :unit

      t.timestamps
    end
  end
end
