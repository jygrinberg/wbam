class AddTargtToChart < ActiveRecord::Migration
  def change
    add_column :charts, :target, :string
  end
end
