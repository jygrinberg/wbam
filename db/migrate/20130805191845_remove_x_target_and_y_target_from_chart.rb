class RemoveXTargetAndYTargetFromChart < ActiveRecord::Migration
  def change
    remove_column :charts, :x_target, :string
    remove_column :charts, :y_target, :string
  end
end
