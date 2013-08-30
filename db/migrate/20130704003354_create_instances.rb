class CreateInstances < ActiveRecord::Migration
  def change
    create_table :instances do |t|
      t.string :instance_id
      t.string :zone

      t.timestamps
    end
  end
end
