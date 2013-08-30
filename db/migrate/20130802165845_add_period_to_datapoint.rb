class AddPeriodToDatapoint < ActiveRecord::Migration
  def change
    add_column :datapoints, :period, :integer
  end
end
