class CreateCharts < ActiveRecord::Migration
  def change
    create_table :charts do |t|
      t.boolean :time_based
      t.integer :start_time
      t.integer :end_time
      t.integer :interval
      t.string :x_metric_name
      t.string :x_data_type
      t.string :x_target
      t.string :y_metric_name
      t.string :y_data_type
      t.string :y_target
      t.integer :dashboard_id
      t.integer :chart_number

      t.timestamps
    end
  end
end
