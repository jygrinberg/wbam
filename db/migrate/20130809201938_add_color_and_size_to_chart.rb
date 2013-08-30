class AddColorAndSizeToChart < ActiveRecord::Migration
  def change
    add_column :charts, :color, :string
    add_column :charts, :size, :string
  end
end
