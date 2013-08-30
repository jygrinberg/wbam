class AddNameToInstances < ActiveRecord::Migration
  def change
    add_column :instances, :name, :string
  end
end
