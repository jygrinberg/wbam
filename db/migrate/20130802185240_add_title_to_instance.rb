class AddTitleToInstance < ActiveRecord::Migration
  def change
    add_column :instances, :title, :string, :default => 'Unknown Service'
  end
end
