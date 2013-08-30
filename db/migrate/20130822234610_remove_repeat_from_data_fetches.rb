class RemoveRepeatFromDataFetches < ActiveRecord::Migration
  def change
    remove_column :data_fetches, :repeat, :boolean
  end
end
