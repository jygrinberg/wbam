class RemoveAlarmValuesFromCharts < ActiveRecord::Migration
  def change
    remove_column :charts, :x_alarm_min, :float
    remove_column :charts, :x_alarm_max, :float
    remove_column :charts, :y_alarm_min, :float
    remove_column :charts, :y_alarm_max, :float
  end
end
