class AddAlarmValuesToCharts < ActiveRecord::Migration
  def change
    add_column :charts, :x_alarm_min, :float, :default => 0, :nil => false
    add_column :charts, :x_alarm_max, :float, :default => 1, :nil => false
    add_column :charts, :y_alarm_min, :float, :default => 0, :nil => false
    add_column :charts, :y_alarm_max, :float, :default => 1, :nil => false
  end
end
