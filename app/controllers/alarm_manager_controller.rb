class AlarmManagerController < ApplicationController
    def index
        @metric_data = Metric.group('metric_name, data_type').inject({}) do |data, metric|
            metric_name = metric.metric_name
            data[metric_name.to_sym] = {namespace: metric.namespace, data_types: [], unit_pretty: metric.unit_pretty} if data[metric_name.to_sym].nil?
            data[metric_name.to_sym][:data_types] << metric.data_type
            data
        end
    end

    def create_alarm
        current_time = Time.now.utc
        metric = Metric.where(metric_name: params['metric_name'], data_type: params['data_type'], target: 'load_balancer').first
        alarm = Alarm.create(
            metric: metric,
            period: params[:interval].to_i*60,
            relation: params[:relation],
            threshold: params[:threshold].to_i,
            min_length_sec: params[:min_length_sec].to_i
        )

        #alarm_stats = {alarm_id: alarm.id, alarm_stats: get_stats_for_alarm(alarm, current_time
        #render json: {alarm_stats: alarm_stats, alarm_description: alarm.description, num_lbs: LoadBalancer.where('name != "N/A"').count }
        #redirect_to '/alarm_manager/index/'
        render :nothing => true
        return false
    end

    def remove_alarm
        alarm_id = params[:alarm_id]
        Alarm.find(alarm_id).delete if Alarm.exists?(alarm_id)

        render :nothing => true
        return false
    end

    def get_alarms
        current_time = Time.now.utc
        alarms = Alarm.all
        alarms_stats = []
        time_range_min = 60;
        start_time = current_time - time_range_min*60
        alarms.each do |alarm|
            alarms_stats << {alarm_id: alarm.id, alarm_stats: get_stats_for_alarm(alarm, start_time)}
        end

        render json: {alarms_stats: alarms_stats, current_time: current_time.strftime(Settings[:time_format_seconds]), start_time: start_time.strftime(Settings.time_format), num_lbs: LoadBalancer.where('name != "N/A"').count }
    end

    private
    def get_stats_for_alarm(alarm, start_time)
        alarm_stats = []

        LoadBalancer.where('name != "N/A"').each do |lb|
            dps_alarm_count = Datapoint.where(metric: alarm.metric, loadBalancer: lb, period: alarm.period).where('timestamp >= ?', start_time).where("value #{alarm.relation} ?", alarm.threshold).count
            dps_total_count = Datapoint.where(metric: alarm.metric, loadBalancer: lb, period: alarm.period).where('timestamp >= ?', start_time).count
            status = 'OK' if dps_alarm_count.nil? || dps_alarm_count == 0
            status = 'FAIL' if dps_alarm_count > 0
            if dps_alarm_count > 0 && dps_total_count > 0
                message = dps_alarm_count.to_s + '/' + dps_total_count.to_s + ' datapoints (' + (dps_alarm_count*100.0/dps_total_count).to_i.to_s + '%)'
            end

            message ||= ''

            alarm_stats.push(
                {
                    lb_name: lb.name.to_s,
                    status: status,
                    message: message
                }
            )
        end
        return alarm_stats
    end
end
