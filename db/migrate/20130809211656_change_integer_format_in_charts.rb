class ChangeIntegerFormatInCharts < ActiveRecord::Migration
  def change
      change_column :charts, :x_alarm_min, :float
      change_column :charts, :x_alarm_max, :float
      change_column :charts, :y_alarm_min, :float
      change_column :charts, :y_alarm_max, :float
  end
end
