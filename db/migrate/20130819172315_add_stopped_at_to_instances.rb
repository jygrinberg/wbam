class AddStoppedAtToInstances < ActiveRecord::Migration
  def change
    add_column :instances, :stopped_at, :datetime
  end
end
