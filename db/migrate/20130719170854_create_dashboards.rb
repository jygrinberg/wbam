class CreateDashboards < ActiveRecord::Migration
  def change
    create_table :dashboards do |t|
      t.string :name
      t.integer :rows
      t.integer :cols

      t.timestamps
    end
  end
end
