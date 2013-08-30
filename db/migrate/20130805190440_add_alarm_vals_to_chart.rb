class AddAlarmValsToChart < ActiveRecord::Migration
  def change
    add_column :charts, :x_alarm_min, :integer
    add_column :charts, :x_alarm_max, :integer
    add_column :charts, :y_alarm_min, :integer
    add_column :charts, :y_alarm_max, :integer
  end
end
