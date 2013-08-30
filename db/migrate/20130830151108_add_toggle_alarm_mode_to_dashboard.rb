class AddToggleAlarmModeToDashboard < ActiveRecord::Migration
  def change
    add_column :dashboards, :toggle_alarm_mode, :boolean
  end
end
