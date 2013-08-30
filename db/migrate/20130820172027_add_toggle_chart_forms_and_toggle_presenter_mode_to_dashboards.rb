class AddToggleChartFormsAndTogglePresenterModeToDashboards < ActiveRecord::Migration
  def change
    add_column :dashboards, :toggle_chart_forms, :boolean
    add_column :dashboards, :toggle_presenter_mode, :boolean
  end
end
