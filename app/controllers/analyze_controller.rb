class AnalyzeController < ApplicationController
    respond_to :js, :html

    MAX_DPS_PER_SERIES = 10000
    TIME_AXIS = -1
    SERIES_COLORS = %w(#2f7ed8 #e39900 #8bbc21 #910000 #1aadce #492970 #f28f43 #77a1e5 #c42525 #a6c96a)

    MAX_RADIUS_LINE_PX = 20
    MAX_RADIUS_SCATTER_PX = 40
    MIN_RADIUS_PX = 5
    DEFAULT_RADIUS_LINE_PX = 8
    DEFAULT_RADIUS_SCATTER_PX = 14
    ALARM_COLOR = 'red'
    ALARM_RADIUS_LINE_PX = MAX_RADIUS_LINE_PX * 2
    ALARM_RADIUS_SCATTER_PX = MAX_RADIUS_SCATTER_PX * 2

    def index
        #Rails.cache.clear
        @dashboard = nil
        @dashboard = Dashboard.find(params[:id].to_i) if (!params[:id].nil? && (params[:id] =~ /^\d+$/) && !Dashboard.where(id: params[:id].to_i).blank?)

        if @dashboard.nil? then
            @dashboard = Dashboard.first
            @dashboard = Dashboard.create(name: 'Sample Dashboard') if @dashboard.nil?
        end
        session[:dashboard_id] = @dashboard.id
    end

    def generate
        @time = []
        @time.push(['start', Time.now.utc])

        @is_time_based = (params[:toggle_chart_type] == 'bar' || params[:toggle_chart_type] == 'line') ? true : false

        dashboard = Dashboard.find(session[:dashboard_id]) unless session[:dashboard_id].nil?
        toggle_alarm_mode = dashboard.toggle_alarm_mode unless dashboard.nil?

        end_datetime = params[:end_time].to_i.minutes.ago
        start_datetime = params[:start_time].to_i.minutes.ago

        params[:x_metric_name] = 'time' if @is_time_based

        x_metric = get_metric_for_id(params[:x_metric_name], params[:x_data_type], params[:target])
        y_metric = get_metric_for_id(params[:y_metric_name], params[:y_data_type] ,params[:target])

        x_beanstalks = get_beanstalks_for_target(params[:target], x_metric)
        y_beanstalks = get_beanstalks_for_target(params[:target], y_metric)

        @time.push(['got beanstalks', Time.now.utc])

        x_data = get_series_data_for_axis(x_metric, x_beanstalks, start_datetime, end_datetime, params[:interval].to_i)
        y_data = get_series_data_for_axis(y_metric, y_beanstalks, start_datetime, end_datetime, params[:interval].to_i)

        @time.push(['got data', Time.now.utc])

        x_axis_range = get_range_for_axis(x_metric, params[:x_axis_min], params[:x_axis_max])
        y_axis_range = get_range_for_axis(y_metric, params[:y_axis_min], params[:y_axis_max])

        metadata = merge_and_process_datapoints(x_data, y_data, x_metric, y_metric, x_axis_range, y_axis_range, toggle_alarm_mode)
        data = metadata[:data]
        alarm_failed = metadata[:alarm_failed]

        alarm_failed = (alarm_failed && toggle_alarm_mode)

        x_axis_title = get_axis_title_for_metric(x_metric)
        y_axis_title = get_axis_title_for_metric(y_metric)

        chart_title = get_chart_title(@is_time_based, x_metric, y_metric)
        chart_subtitle  = get_chart_subtitle(params[:toggle_color], params[:toggle_size])

        chart_data = {
            data: data.to_json, # TODO extremely time-intensive -- use Oj gem instead?
            chart_type: params[:toggle_chart_type],
            x_axis_title: x_axis_title,
            y_axis_title: y_axis_title,
            x_axis_range: x_axis_range,
            y_axis_range: y_axis_range,
            chart_title: chart_title,
            chart_subtitle: chart_subtitle,
            alarm_failed: alarm_failed,
            time: Time.now.utc
        }

        @time.push(['done', Time.now.utc])

        start = @time[0][1]
        @time.each do |label, time|
            puts label.to_s + ': ' + (time.to_f - start.to_f).to_s
        end

        render json: chart_data
        return false;
    end

    def get_metric_for_id(metric_name, data_type, target)
        if metric_name.downcase == 'time' then
            return TIME_AXIS
        end
        target = 'instance' if target.match(/^i-/) || target.match(/all_instances/)
        target = 'load_balancer' if target.match(/^lb-/) || target.match(/all_load_balancers/) || (Metric.where('metric_name LIKE ? ', metric_name).first.namespace == 'AWS/ELB' && target != 'website_total')
        metric = Metric.where('metric_name LIKE ? AND data_type LIKE ? AND target LIKE ?', metric_name, data_type, target).first
        return (metric.nil?)? Metric.all.first : metric
    end

    def get_beanstalks_for_target(target, metric) # (target, metric, start, end, period)
        beanstalks = []
        return beanstalks if metric == TIME_AXIS || metric.nil?

        if target=="all_instances" then
            instances = Instance.where("name != 'N/A'").pluck(:id)
            instances.each do |i|
                instance = Instance.find(i)
                if metric.namespace == 'AWS/EC2' then
                    beanstalks << {:instance => i, :loadBalancer => "all", :title => instance.title + ' (instance: ' + instance.name + ')'}
                elsif metric.namespace == 'AWS/ELB' then
                    lb = instance.loadBalancer.id unless instance.loadBalancer.nil?
                    beanstalks << {:instance => i, :loadBalancer => lb, :title => instance.title + ' (load balancer for instance: ' + instance.name + ')'}
                end
            end
        elsif target=="all_load_balancers" then
            loadBalancers = Datapoint.where("metric_id = ?", metric).distinct.pluck(:loadBalancer_id)
            loadBalancers.each do |lb|
                loadBalancer = LoadBalancer.find(lb)
                beanstalks << {:instance => "all", :loadBalancer => lb, :title => loadBalancer.title + ' (load balancer: ' + loadBalancer.name[-4..-1] + ')'}
            end
        elsif target=="website_total" then
            beanstalks << {:instance => "all", :loadBalancer => "all", :title => "Website total"}
        elsif target.match(/^i-/) then
            i = target.split(/^i-/)[1].to_i
            instance = Instance.find(i)

            if metric.namespace == 'AWS/EC2' then
                beanstalks << {:instance => i, :loadBalancer => "all", :title => instance.title + ' (instance: ' + instance.name + ')'}
            elsif metric.namespace == 'AWS/ELB' then
                lb_id = instance.loadBalancer.id unless instance.loadBalancer.nil?
                beanstalks << {:instance => i, :loadBalancer => lb_id, :title => instance.title + ' (load balancer for instance: ' + instance.name + ')'}
            end
        elsif target.match(/^lb-/) then
            lb = target.split(/^lb-/)[1].to_i
            loadBalancer = LoadBalancer.find(lb)
            beanstalks << {:instance => "all", :loadBalancer => lb, :title => loadBalancer.title + ' (load balancer: ' + loadBalancer.name[-4..-1] + ')'}
        end

        return beanstalks
    end

    def get_series_data_for_axis(metric, beanstalks, start_datetime, end_datetime, interval_min)
        series = []

        if metric == TIME_AXIS then
            series = TIME_AXIS
        else
            beanstalks.each do |b|
                period = (metric.namespace == 'AWS/EC2' && interval_min < 5)? 5*60 : interval_min * 60      # minimum period for EC2 metrics is 5 min

                #time = []
                #time.push(['starting fetch', Time.now.utc])

                if b[:instance] == 'all' && b[:loadBalancer] == 'all' then
                    datapoints = Datapoint.where('timestamp >= ?', start_datetime).where('timestamp <= ?', end_datetime).where('period = ?', period).where('metric_id = ?', metric).order('timestamp ASC').to_a
                elsif b[:loadBalancer].is_a? Integer then
                    datapoints = Datapoint.where('timestamp >= ?', start_datetime).where('timestamp <= ?', end_datetime).where('period = ?', period).where('metric_id = ?', metric).where('loadBalancer_id = ?', b[:loadBalancer]).order('timestamp ASC').to_a
                elsif b[:instance].is_a? Integer then
                    datapoints = Datapoint.where('timestamp >= ?', start_datetime).where('timestamp <= ?', end_datetime).where('period = ?', period).where('metric_id = ?', metric).where('instance_id = ?', b[:instance]).order('timestamp ASC').to_a
                end

                #time.push(['fetch ended', Time.now.utc])

                #start = time[0][1]
                #time.each do |label, time|
                #    puts label.to_s + ': ' + (time.to_f - start.to_f).to_s
                #end

                metadata = {:title => b[:title], :instance_id => b[:instance], :loadBalancer_id => b[:loadBalancer]}
                series << {:datapoints => datapoints, :metadata => metadata}
            end
        end
        return series
    end

    def merge_and_process_datapoints(x_data, y_data, x_metric, y_metric, x_axis_range, y_axis_range, toggle_alarm_mode)
        data = []

        alarm_failed = false

        if params[:toggle_color] == 'time' || params[:toggle_size] == 'time'
            time_range = find_time_range_for_data(x_data, y_data)
        end

        if params[:toggle_color] == 'value' || params[:toggle_size] == 'value'
            x_acceptable_value_range = find_acceptable_value_range_for_axis_data(x_data, x_metric, x_axis_range, toggle_alarm_mode)
            y_acceptable_value_range = find_acceptable_value_range_for_axis_data(y_data, y_metric, y_axis_range, toggle_alarm_mode)
            acceptable_value_range = {x: x_acceptable_value_range, y: y_acceptable_value_range}
        end

        desired_min_x = Alarm.where(metric: x_metric, relation: '<').pluck('threshold').to_a.first if x_data != TIME_AXIS && toggle_alarm_mode
        desired_max_x = Alarm.where(metric: x_metric, relation: '>').pluck('threshold').to_a.first if x_data != TIME_AXIS && toggle_alarm_mode

        desired_min_y = Alarm.where(metric: y_metric, relation: '<').pluck('threshold').to_a.first if toggle_alarm_mode
        desired_max_y = Alarm.where(metric: y_metric, relation: '>').pluck('threshold').to_a.first if toggle_alarm_mode

        if x_data == TIME_AXIS then
            num_series = y_data.length

            num_series.times do |i|
                series_i = {}
                series_i[:name] = y_data[i][:metadata][:title]
                series_i[:color] = SERIES_COLORS[i % SERIES_COLORS.size]
                series_i[:data] = []

                y_data[i][:datapoints].each do |dp|

                    if (params[:toggle_color] == 'time' || params[:toggle_size] == 'time') && time_range[:span] > 0 then
                        time_scale = (dp.timestamp.to_i - time_range[:min_timestamp].to_i).to_f / time_range[:span]

                        color = 'rgb('+(time_scale*255).to_i.to_s+','+(255-time_scale*255).to_i.to_s+','+(time_scale*255).to_i.to_s+')' if params[:toggle_color] == 'time'
                        radius = (time_scale*MAX_RADIUS_LINE_PX + MIN_RADIUS_PX).to_i if params[:toggle_size] == 'time'
                    end

                    if params[:toggle_color] == 'value' || params[:toggle_size] == 'value' then
                        value_scale = (dp.value - acceptable_value_range[:y][:min]).to_f / acceptable_value_range[:y][:span] unless acceptable_value_range[:y][:span] == 0
                        is_alarm_dp = !value_scale || value_scale > 1 || value_scale < 0

                        if params[:toggle_color] == 'value' then
                            color = ALARM_COLOR if is_alarm_dp && toggle_alarm_mode
                            color ||= 'rgb('+(value_scale*255).to_i.to_s+','+(255-value_scale*200).to_i.to_s+','+(0).to_i.to_s+')'
                        end

                        if params[:toggle_size] == 'value' then
                            radius = ALARM_RADIUS_LINE_PX if is_alarm_dp && toggle_alarm_mode
                            radius ||= (value_scale*MAX_RADIUS_LINE_PX + MIN_RADIUS_PX).to_i
                        end
                    end

                    if params[:toggle_size] == 'static' || radius.nil? then
                        radius = DEFAULT_RADIUS_LINE_PX
                    end

                    alarm_failed = true if toggle_alarm_mode &&
                        (!desired_max_y.nil? && dp.value > desired_max_y) ||
                        (!desired_min_y.nil? && dp.value < desired_min_y)

                    series_i[:data] << { :x => dp.timestamp.to_i*1000, :y => dp.value.to_f, :timestamp => dp.timestamp.strftime(Settings.time_format), :marker => { fillColor: color, lineColor: 'black', lineWidth: 2, radius: radius, states: {hover: {fillColor: color, lineColor: 'black', lineWidth: 3, radius: radius+2} } } }
                end

                data.push(series_i) unless series_i[:data].empty?
            end
        else
            merged_data = {}

            if params[:target] == 'all_instances' || params[:target].match(/^i-/) then
                series_id_indicator = 'instance_id'.to_sym
            else
                series_id_indicator = 'loadBalancer_id'.to_sym
            end

            x_data.each do |series|
                series_id = series[:metadata][series_id_indicator].to_s.to_sym

                merged_data[series_id] = {x_title: '', y_title: '', data: {}} if merged_data[series_id].nil?
                merged_data[series_id][:x_title] = series[:metadata][:title]
                series[:datapoints].each do |dp|
                    timestamp_ms_sym = dp.timestamp.to_s.to_sym
                    merged_data[series_id][:data][timestamp_ms_sym] = {timestamp: dp.timestamp} if merged_data[series_id][:data][timestamp_ms_sym].nil?
                    merged_data[series_id][:data][timestamp_ms_sym][:x] = dp.value
                end
            end

            y_data.each do |series|
                series_id = series[:metadata][series_id_indicator].to_s.to_sym

                merged_data[series_id] = {x_title: '', y_title: '', data: {}} if merged_data[series_id].nil?
                merged_data[series_id][:y_title] = series[:metadata][:title]
                series[:datapoints].each do |dp|
                    timestamp_ms_sym = dp.timestamp.to_s.to_sym
                    merged_data[series_id][:data][timestamp_ms_sym] = {timestamp: dp.timestamp} if merged_data[series_id][:data][timestamp_ms_sym].nil?
                    merged_data[series_id][:data][timestamp_ms_sym][:y] = dp.value
                end
            end

            merged_data.each_with_index do |(title, merged_series_i), i|
                series_i = {}
                series_i[:name] = merged_series_i[:x_title]
                series_i[:color] = SERIES_COLORS[i % SERIES_COLORS.size]
                series_i[:data] = []

                merged_series_i[:data].each do |timestamp, vals|
                    x_val = vals[:x]
                    y_val = vals[:y]
                    timestamp = vals[:timestamp]

                    next if x_val.nil? || y_val.nil?

                    if (params[:toggle_color] == 'time' || params[:toggle_size] == 'time') && time_range[:span] > 0 then
                        time_scale = (timestamp.to_i - time_range[:min_timestamp].to_i).to_f / time_range[:span]
                        color = 'rgb('+(time_scale*255).to_i.to_s+','+(255-time_scale*255).to_i.to_s+','+(time_scale*255).to_i.to_s+')' if params[:toggle_color] == 'time'
                        radius = (time_scale*MAX_RADIUS_SCATTER_PX + MIN_RADIUS_PX).to_i if params[:toggle_size] == 'time'
                    end

                    if params[:toggle_color] == 'value' || params[:toggle_size] == 'value' then
                        x_acceptable_value_scale = (x_val - acceptable_value_range[:x][:min]).to_f / acceptable_value_range[:x][:span] unless acceptable_value_range[:x][:span] == 0
                        y_acceptable_value_scale = (y_val - acceptable_value_range[:y][:min]).to_f / acceptable_value_range[:y][:span] unless acceptable_value_range[:y][:span] == 0
                        value_scale = [x_acceptable_value_scale, y_acceptable_value_scale].max unless !x_acceptable_value_scale || !y_acceptable_value_scale

                        is_alarm_dp = !value_scale || x_acceptable_value_scale < 0 || x_acceptable_value_scale > 1 || y_acceptable_value_scale < 0 || y_acceptable_value_scale > 1

                        if params[:toggle_color] == 'value' then
                            color = ALARM_COLOR if is_alarm_dp && toggle_alarm_mode
                            color ||= 'rgb('+(value_scale*255).to_i.to_s+','+(255-value_scale*200).to_i.to_s+','+(0).to_i.to_s+')'
                        end
                        if params[:toggle_size] == 'value' then
                            radius = ALARM_RADIUS_SCATTER_PX if is_alarm_dp && toggle_alarm_mode
                            radius ||= (value_scale*MAX_RADIUS_SCATTER_PX + MIN_RADIUS_PX).to_i
                        end
                    end

                    if params[:toggle_size] == 'static' || radius.nil? then
                        radius = DEFAULT_RADIUS_SCATTER_PX
                    end

                    alarm_failed = true if toggle_alarm_mode &&
                        (!desired_max_x.nil? && x_val > desired_max_x) ||
                        (!desired_min_x.nil? && x_val < desired_min_x) ||
                        (!desired_max_y.nil? && y_val > desired_max_y) ||
                        (!desired_min_y.nil? && y_val < desired_min_y) ||

                    series_i[:data] << { :x => x_val.to_f, :y => y_val.to_f, :timestamp => timestamp.strftime(Settings.time_format), :marker => { fillColor: color, lineColor: 'black', lineWidth: 2, radius: radius, states: {hover: {fillColor: color, lineColor: 'black', lineWidth: 3, radius: radius+2} } } }
                end

                series_i[:data][-1][:marker][:last] = true unless series_i[:data].empty?  # emphasize latest datapoint

                data << series_i unless series_i[:data].empty?
            end
        end

        return {data: data, alarm_failed: alarm_failed}
    end

    def find_time_range_for_data(x_data, y_data)
        min_timestamp = nil
        max_timestamp = nil
        unless x_data.nil? || x_data == TIME_AXIS
            x_data.each do |series_i|
                dps = series_i[:datapoints]
                next if (dps.nil? || dps.empty?)
                min_timestamp_for_series = dps.first.timestamp
                min_timestamp = min_timestamp_for_series if (min_timestamp.nil? || min_timestamp_for_series < min_timestamp)

                max_timestamp_for_series = dps.last.timestamp
                max_timestamp = max_timestamp_for_series if (max_timestamp.nil? || max_timestamp_for_series > max_timestamp)
            end
        end
        unless y_data.nil?
            y_data.each do |series_i|
                dps = series_i[:datapoints]
                next if (dps.nil? || dps.empty?)
                min_timestamp_for_series = dps.first.timestamp
                min_timestamp = min_timestamp_for_series if (min_timestamp.nil? || min_timestamp_for_series < min_timestamp)

                max_timestamp_for_series = dps.last.timestamp
                max_timestamp = max_timestamp_for_series if (max_timestamp.nil? || max_timestamp_for_series > max_timestamp)
            end
        end

        return {min_timestamp: min_timestamp, max_timestamp: max_timestamp, span: (max_timestamp.to_i - min_timestamp.to_i)}
    end

    def find_acceptable_value_range_for_axis_data(data, metric, axis_range, toggle_alarm_mode)
        return {} if data.nil? || data == TIME_AXIS

        desired_min = Alarm.where(metric: metric, relation: '<').pluck('threshold').to_a.first if toggle_alarm_mode
        desired_min ||= axis_range[:min]
        min = desired_min

        desired_max = Alarm.where(metric: metric, relation: '>').pluck('threshold').to_a.first if toggle_alarm_mode
        desired_max ||= axis_range[:max]
        max = desired_max

        if desired_min.nil? || desired_max.nil?
            data.each do |series_i|
                dps = series_i[:datapoints]
                next if (dps.nil? || dps.empty?)

                min_value_for_series = dps.min_by {|dp| dp.value }.value
                min = min_value_for_series if (desired_min.nil? && (min.nil? || min_value_for_series < min))

                max_value_for_series = dps.max_by {|dp| dp.value }.value
                max = max_value_for_series if (desired_max.nil? && (max.nil? || max_value_for_series > max))
            end
        end

        span = max - min unless (max.nil? || min.nil?)

        return {min: min, max: max, span: span}
    end

    def get_num_dp_per_series(x_data, y_data, num_series)
        num = MAX_DPS_PER_SERIES
        num_series.times do |i|
            if x_data == TIME_AXIS then
                num_dp_for_series_i = y_data[i][:datapoints].length
            else
                num_dp_for_series_i = [x_data[i][:datapoints].length, y_data[i][:datapoints].length].min
            end
            num = [num_dp_for_series_i, num].min
        end
        return num
    end

    def merge_series_title(x_title, y_title)
        return x_title if (x_title == y_title || y_title.include?('N/A'))
        return y_title if x_title.include?('N/A')
        return x_title + " == ".html_safe + y_title
    end

    def get_axis_title_for_metric(metric)
        if metric == TIME_AXIS then
            return 'Time'
        end
        units = (metric.unit.downcase == "percent") ? "Percent" : metric.unit.capitalize.pluralize(2)
        return metric.metric_name + "-" + metric.data_type + " [" + units + "]"
    end

    def get_range_for_axis(metric, axis_min, axis_max)
        range = {}

        if metric == TIME_AXIS then
            return range
        end

        range[:min] = axis_min.to_f unless axis_min.nil? || axis_min.empty?
        range[:max] = axis_max.to_f unless axis_max.nil? || axis_max.empty?

        return range
    end

    def get_chart_title(is_time_based, x_metric, y_metric)
        return chart_title = y_metric.metric_name if is_time_based
        return chart_title = x_metric.metric_name + '   v.   ' + y_metric.metric_name
    end

    def get_chart_subtitle(toggle_color, toggle_size)
        chart_subtitle = ''
        if params[:toggle_color] == 'value'
            chart_subtitle += 'Color: <span style="font-weight:bold;color:#00FF00">GREEN LOW VALUES</span> <span style="color:888888"> to </span> <span style="font-weight:bold;color:#FF00FF">PURPLE HIGH VALUES</span>'
        elsif params[:toggle_color] == 'time'
            chart_subtitle += 'Color: <span style="font-weight:bold;color:#00FF00">GREEN OLD DATA</span> <span style="color:888888"> to </span> <span style="font-weight:bold;color:#FF00FF">PURPLE NEW DATA</span>'
        end

        chart_subtitle += '<br>' if !chart_subtitle.empty?
        if params[:toggle_size] == 'value'
            chart_subtitle += 'Size: small low values to BIG HIGH VALUES'
        elsif params[:toggle_size] == 'time'
            chart_subtitle += 'Size: small old data to BIG NEW DATA'
        end

        return chart_subtitle
    end

    def get_metric_data
        metric_data = Metric.group('metric_name, data_type').inject({}) do |data, metric|
            metric_name = metric.metric_name
            data[metric_name.to_sym] = {namespace: metric.namespace, data_types: [], unit_pretty: metric.unit_pretty} if data[metric_name.to_sym].nil?
            data[metric_name.to_sym][:data_types] << metric.data_type
            data
        end

        render json: {:metric_data => metric_data }
    end

    def cycle_dashboards
        dashboard = session[:dashboard]
        dashboard = Dashboard.first if dashboard.nil?

        session[:dashboard] = dashboard

        render "analyze/index"
    end
end
