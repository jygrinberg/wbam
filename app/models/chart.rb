class Chart < ActiveRecord::Base
    attr_accessible :dashboard, :chart_number, :chart_type, :target, :start_time, :end_time, :interval,
                    :x_metric_name, :x_data_type, :y_metric_name, :y_data_type,
                    :x_alarm_min, :x_alarm_max, :y_alarm_min, :y_alarm_max,
                    :x_axis_min, :x_axis_max, :y_axis_min, :y_axis_max,
                    :color, :size

    belongs_to :dashboard

    before_save :delete_duplicates
    after_initialize :default_values

    def delete_duplicates
        Chart.where('dashboard_id = ?', self.dashboard_id).where('chart_number = ?', self.chart_number).each { |dup| dup.destroy! }
    end

    def default_values
        default_dashboard = Dashboard.first
        default_metric = Metric.first

        self.dashboard ||= default_dashboard
        self.chart_number ||= default_dashboard.charts.count
        self.target ||= 'all_load_balancers'
        self.chart_type ||= 'bar'
        self.start_time ||= 60
        self.end_time ||= 0
        self.interval ||= 1
        self.x_metric_name ||= default_metric.metric_name
        self.x_data_type ||= default_metric.data_type
        self.y_metric_name ||= default_metric.metric_name
        self.y_data_type ||= default_metric.data_type
        self.color ||= 'static'
        self.size ||= 'static'

        return true
    end
end
