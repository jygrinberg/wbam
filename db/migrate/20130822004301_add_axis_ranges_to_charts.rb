class AddAxisRangesToCharts < ActiveRecord::Migration
  def change
    add_column :charts, :x_axis_min, :float
    add_column :charts, :x_axis_max, :float
    add_column :charts, :y_axis_min, :float
    add_column :charts, :y_axis_max, :float
  end
end
