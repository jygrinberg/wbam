class SettingsController < ApplicationController

def save
    settings = Rack::Utils.parse_nested_query(params[:settings])
    chart_forms = params[:charts].map { |c| Rack::Utils.parse_nested_query(c)}

    dashboard_id = session[:dashboard_id]
    dashboard = Dashboard.find(dashboard_id)

    dashboard.rows = settings['display_rows'].to_i unless settings['display_rows'].nil?
    dashboard.cols = settings['display_cols'].to_i unless settings['display_cols'].nil?
    dashboard.toggle_chart_forms = settings['toggle_chart_settings']
    dashboard.toggle_presenter_mode = settings['toggle_display_mode']
    dashboard.toggle_alarm_mode = settings['toggle_alarm_mode']

    dashboard.save

    chart_forms.each do |chart|
        chart_number = chart["id"].gsub(/[^\d]/, '')   # extract digits from id
        c = Chart.new(:start_time => chart['start_time'],
                     :end_time => chart['end_time'],
                     :interval => chart['interval'],
                     :y_metric_name => chart['y_metric_name'],
                     :y_data_type => chart['y_data_type'],
                     :x_axis_min => chart['x_axis_min'],
                     :x_axis_max => chart['x_axis_max'],
                     :y_axis_min => chart['y_axis_min'],
                     :y_axis_max => chart['y_axis_max'],
                     :target => chart['target'],
                     :chart_type => chart['toggle_chart_type'],
                     :color => chart['toggle_color'],
                     :size => chart['toggle_size'],
                     :chart_number => chart_number,
                     :dashboard => dashboard)
        if chart['toggle_chart_type'] == 'bar' || chart['toggle_chart_type'] == 'line' then
            # save dummy variables for x parameters
            c.x_metric_name = chart['y_metric_name']
            c.x_data_type = chart['y_data_type']
            c.x_axis_min = chart['y_axis_min']
            c.x_axis_max = chart['y_axis_max']
        else
            c.x_metric_name = chart['x_metric_name']
            c.x_data_type = chart['x_data_type']
            c.x_axis_min = chart['x_axis_min']
            c.x_axis_max = chart['x_axis_max']
        end
        c.save
    end

    render partial: "/analyze/chart_canvas"
end

end
