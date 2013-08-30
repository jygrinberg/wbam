class AddRepeatFrequencySecToDataFetches < ActiveRecord::Migration
  def change
    add_column :data_fetches, :repeat_frequency_sec, :integer
  end
end
