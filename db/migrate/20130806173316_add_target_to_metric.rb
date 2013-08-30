class AddTargetToMetric < ActiveRecord::Migration
  def change
    add_column :metrics, :target, :string
  end
end
