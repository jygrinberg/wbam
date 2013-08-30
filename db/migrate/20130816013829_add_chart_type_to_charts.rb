class AddChartTypeToCharts < ActiveRecord::Migration
  def change
    add_column :charts, :chart_type, :string
  end
end
