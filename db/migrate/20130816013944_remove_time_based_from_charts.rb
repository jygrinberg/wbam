class RemoveTimeBasedFromCharts < ActiveRecord::Migration
  def change
    remove_column :charts, :time_based, :boolean
  end
end
