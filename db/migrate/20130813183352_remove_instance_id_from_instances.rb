class RemoveInstanceIdFromInstances < ActiveRecord::Migration
  def change
    remove_column :instances, :instance_id, :integer
  end
end
