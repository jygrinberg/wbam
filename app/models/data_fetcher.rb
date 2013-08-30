class DataFetcher < ActiveRecord::Base
    attr_accessible :started_fetch_at, :completed_fetch_at, :start_min_ago, :end_min_ago, :intervals, :metrics, :repeat_frequency_sec, :fetch_count

    ALL_PERIODS = [1*60, 5*60, 60*60, 60*60*24, 60*60*24*7]
    DEFAULT_START_MIN_AGO = 5
    DEFAULT_END_MIN_AGO = 0
    DEFAULT_INTERVAL = 'all'    # currently only the default value 'all' is supported
    DEFAULT_METRICS = 'all'     # currently only the default value 'all' is supported
    DEFAULT_PERIOD = 'all'      # currently only the default value 'all' is supported
    DEFAULT_REPEAT_FREQUENCY_SEC = 3*60
    NO_REPEAT_SIGNAL = 0

    after_initialize :default_values

    def default_values
        self.start_min_ago ||= DEFAULT_START_MIN_AGO
        self.start_min_ago = DEFAULT_START_MIN_AGO if self.start_min_ago < DEFAULT_START_MIN_AGO
        self.end_min_ago ||= DEFAULT_END_MIN_AGO
        self.intervals ||= DEFAULT_INTERVAL
        self.metrics ||= DEFAULT_METRICS
        self.periods ||= DEFAULT_PERIOD
        self.repeat_frequency_sec ||= DEFAULT_REPEAT_FREQUENCY_SEC
        self.fetch_count ||= 0

        return true
    end

    def fetch_cloudwatch_data
        self.started_fetch_at = Time.now.utc
        self.completed_fetch_at = nil
        self.save

        metrics = Metric.all.distinct.pluck(:metric_name, :data_type, :namespace).map { |m| {metric_name: m[0], data_type: m[1], namespace: m[2] } } if self.metrics == 'all'
        periods = ALL_PERIODS if self.periods == 'all'

        Settings.aws.accounts.each do |aws_account|
            fetch_cloudwatch_data_for_account(aws_account, metrics, periods, self.started_fetch_at, self.start_min_ago, self.end_min_ago)
        end

        self.completed_fetch_at = Time.now.utc
        self.fetch_count = self.fetch_count + 1
        self.save

        unless self.repeat_frequency_sec == NO_REPEAT_SIGNAL then
            wait_sec = self.started_fetch_at + self.repeat_frequency_sec.seconds - Time.now.utc
            wait_sec = 0 if wait_sec < 0
            delay({:run_at => wait_sec.seconds.from_now}).fetch_cloudwatch_data
        end

        #remove_old_datapoints
    end

    private
    def remove_old_datapoints
        Datapoint.where('period = ? AND timestamp < ?', 60, self.started_fetch_at - (3*60*24).minutes).destroy_all
        Datapoint.where('period = ? AND timestamp < ?', 60*5, self.started_fetch_at - (7*60*24).minutes).destroy_all
        Datapoint.where('period = ? AND timestamp < ?', 60*60, self.started_fetch_at - (4*7*60*24).minutes).destroy_all
    end

    private
    def fetch_cloudwatch_data_for_account(aws_account, metrics, periods, current_time, start_min_ago, end_min_ago)
        return if end_min_ago >= start_min_ago
        AWS.config(access_key_id: aws_account.access_key_id, secret_access_key: aws_account.secret_access_key, region: aws_account.region)
        cw_client = AWS::CloudWatch.new.client

        is_first_data_fetch = Datapoint.all.count == 0

        periods.each do |period|

            current_time_rounded = round_time_for_period(current_time, period)

            earliest_possible_start_time = get_start_time_for_period(current_time_rounded, start_min_ago, period)
            latest_possible_end_time = get_end_time_for_period(current_time_rounded, end_min_ago, period)
            beanstalks = get_beanstalks_for_time_range(earliest_possible_start_time, latest_possible_end_time, is_first_data_fetch)
            next if beanstalks.nil? || beanstalks.empty?

            metrics.each do |metric|
                fetch_ec2_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, end_min_ago) if metric[:namespace] == 'AWS/EC2'
                fetch_elb_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, end_min_ago) if metric[:namespace] == 'AWS/ELB'
            end

        end

    end

    private
    def get_start_time_for_period(current_time_rounded, start_min_ago, period)
        start_sec_ago_rounded = (start_min_ago*60.0 / period).ceil * period
        return (current_time_rounded - start_sec_ago_rounded).to_time.utc
    end

    private
    def get_end_time_for_period(current_time_rounded, end_min_ago, period)
        end_sec_ago_rounded = (end_min_ago*60.0 / period).floor * period
        return (current_time_rounded - end_sec_ago_rounded).to_time.utc
    end

    private
    def round_time_for_period(current_time, period)
        return Time.at((current_time.to_f / period).floor * period).utc
    end

    ##  @retval beanstalks =
    # 	{
    #		loadBalancer1: [instance1, instance2, ...],
    #		loadBalancer2: [instance3, instance4, ...],
    #       ...
    # 	}
    private
    def get_beanstalks_for_time_range(start_time, end_time, is_first_data_fetch)
        beanstalks = {}

        lbs = LoadBalancer.where('created_at <= ?', end_time).where('name != "N/A"').to_a
        lbs = LoadBalancer.where('name != "N/A"').to_a if is_first_data_fetch

        lbs.each do |lb|
            is = Instance.where(loadBalancer: lb).where('created_at < ?', end_time).where('stopped_at IS NULL || (stopped_at <= ? && stopped_at >= ?)', end_time, start_time)
            is = Instance.where(loadBalancer: lb) if is_first_data_fetch
            beanstalks[lb] = is.to_a unless (is.nil? || is.empty?)
        end

        return beanstalks
    end

    private
    def fetch_ec2_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, end_min_ago)
        return if period < 5*60   # min period for ec2 metrics is 5 minutes

        start_time = get_start_time_for_period(current_time_rounded, start_min_ago, period).iso8601
        end_time = get_end_time_for_period(current_time_rounded, end_min_ago, period).iso8601

        data = {}

        beanstalks.each do |lb, instances|

            data[lb] = {}
            instances.each do |i|

                resp = cw_client.get_metric_statistics(
                    :namespace => 'AWS/EC2',
                    :metric_name => metric[:metric_name],
                    :dimensions => [{name: 'InstanceId', value: i.name}],
                    :start_time => start_time,
                    :end_time => end_time,
                    :period => period,
                    :statistics => [metric[:data_type]]
                )
                data[lb][i] = resp.datapoints

            end
        end

        aggregated_data = aggregate_ec2_data(data, metric)

        save_aggregated_data(metric, period, aggregated_data)
    rescue Exception => exception
        if !exception.code.nil? && exception.code == 'InvalidParameterCombination' then
            midpoint_min_ago = ((start_min_ago - end_min_ago) / 2).to_i + end_min_ago
            fetch_ec2_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, midpoint_min_ago)
            fetch_ec2_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, midpoint_min_ago, end_min_ago)
        end
    end

    private
    def fetch_elb_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, end_min_ago)

        start_time = get_start_time_for_period(current_time_rounded, start_min_ago, period).iso8601
        end_time = get_end_time_for_period(current_time_rounded, end_min_ago, period).iso8601

        data = {}

        beanstalks.each do |lb, instances|

            resp = cw_client.get_metric_statistics(
                :namespace => 'AWS/ELB',
                :metric_name => metric[:metric_name],
                :dimensions => [{name: "LoadBalancerName", value: lb.name}],
                :start_time => start_time,
                :end_time => end_time,
                :period => period,
                :statistics => [metric[:data_type]]
            )
            data[lb] = resp.datapoints
        end

        aggregated_data = aggregate_elb_data(data, metric)

        save_aggregated_data(metric, period, aggregated_data)
    rescue Exception => exception
        if !exception.code.nil? && exception.code == 'InvalidParameterCombination' then
            midpoint_min_ago = ((start_min_ago - end_min_ago) / 2).to_i + end_min_ago
            fetch_elb_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, start_min_ago, midpoint_min_ago)
            fetch_elb_data_for_beanstalks(cw_client, metric, period, beanstalks, current_time_rounded, midpoint_min_ago, end_min_ago)
        end
    end

    private
    def aggregate_ec2_data(data, metric)
        return if data.nil?
        metric_type = metric[:data_type]=='SampleCount' ? :sample_count : metric[:data_type].downcase.to_sym

        data_aggregated = { website_total_data: {}, load_balancers: {} }

        data.each do |lb, instances|

            data_aggregated[:load_balancers][lb] = { load_balancer_data: {}, instances: {} }

            instances.each do |i, datapoints|

                data_aggregated[:load_balancers][lb][:instances][i] = { instance_data: {} }

                datapoints.each do |datapoint|
                    value = ('%.3f' % datapoint[metric_type]).to_f
                    timestamp = datapoint[:timestamp]

                    data_aggregated[:load_balancers][lb][:instances][i][:instance_data][timestamp] = {computed_value: value, count: 1}

                    data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp] = {computed_value: 0.0, count: 0} if data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp].nil?
                    data_aggregated[:website_total_data][timestamp] = {computed_value: 0.0, count: 0} if data_aggregated[:website_total_data][timestamp].nil?

                    if metric[:data_type] == 'Sum' then
                        data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value] += value
                        data_aggregated[:website_total_data][timestamp][:computed_value] += value
                    elsif metric[:data_type] == 'Average'
                        lb_value_metadata = data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp]
                        data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value] = (lb_value_metadata[:computed_value] * lb_value_metadata[:count] + value) / (lb_value_metadata[:count] + 1)
                        data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:count] += 1

                        wt_value_metadata = data_aggregated[:website_total_data][timestamp]
                        data_aggregated[:website_total_data][timestamp][:computed_value] = (wt_value_metadata[:computed_value] * wt_value_metadata[:count] + value) / (wt_value_metadata[:count] + 1)
                        data_aggregated[:website_total_data][timestamp][:count] += 1
                    elsif metric[:data_type] == 'Maximum'
                        data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value] = value if value > data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value]
                        data_aggregated[:website_total_data][timestamp][:computed_value] = value if value > data_aggregated[:website_total_data][timestamp][:computed_value]
                    elsif metric[:data_type] == 'Minimum'
                        data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value] = value if value < data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp][:computed_value]
                        data_aggregated[:website_total_data][timestamp][:computed_value] = value if value < data_aggregated[:website_total_data][timestamp][:computed_value]
                    end

                end

            end

        end
        return data_aggregated
    end

    private
    def aggregate_elb_data(data, metric)
        return if data.nil?
        metric_type = metric[:data_type]=='SampleCount' ? :sample_count : metric[:data_type].downcase.to_sym # TODO make elegant

        data_aggregated = { website_total_data: {}, load_balancers: {} }

        data.each do |lb, datapoints|

            data_aggregated[:load_balancers][lb] = { load_balancer_data: {} }
            datapoints.each do |datapoint|
                value = ('%.3f' % datapoint[metric_type]).to_f
                timestamp = datapoint[:timestamp]

                data_aggregated[:load_balancers][lb][:load_balancer_data][timestamp] = {computed_value: value, count: 1}

                data_aggregated[:website_total_data][timestamp] = {computed_value: 0.0, count: 0} if data_aggregated[:website_total_data][timestamp].nil?

                if metric[:data_type] == 'Sum' then
                    data_aggregated[:website_total_data][timestamp][:computed_value] += value
                elsif metric[:data_type] == 'Average'
                    wt_value_metadata = data_aggregated[:website_total_data][timestamp]
                    data_aggregated[:website_total_data][timestamp][:computed_value] = (wt_value_metadata[:computed_value] * wt_value_metadata[:count] + value) / (wt_value_metadata[:count] + 1)
                    data_aggregated[:website_total_data][timestamp][:count] += 1
                elsif metric[:data_type] == 'Maximum'
                    data_aggregated[:website_total_data][timestamp][:computed_value] = value if value > data_aggregated[:website_total_data][timestamp][:computed_value]
                elsif metric[:data_type] == 'Minimum'
                    data_aggregated[:website_total_data][timestamp][:computed_value] = value if value < data_aggregated[:website_total_data][timestamp][:computed_value]
                end
            end

        end
        return data_aggregated
    end

    private
    def save_aggregated_data(metric, period, data_aggregated)
        return if data_aggregated.nil?

        metrics = Metric.where('metric_name = ? AND data_type = ?', metric[:metric_name], metric[:data_type])
        metrics_by_target = Hash[metrics.map { |metric| [metric.target, metric] } ]

        dummy_i = Instance.where("name LIKE 'N/A'").first
        dummy_lb = LoadBalancer.where("name LIKE 'N/A'").first

        # save website_total data
        data_aggregated[:website_total_data].each do |timestamp, value_metadata|
            Datapoint.create(
                :metric => metrics_by_target['website_total'],
                :instance => dummy_i,
                :loadBalancer => dummy_lb,
                :timestamp => timestamp,
                :period => period,
                :value => value_metadata[:computed_value],
            )
        end

        # save load_balancer data
        data_aggregated[:load_balancers].each do |lb, lb_metadata|
            lb_metadata[:load_balancer_data].each do |timestamp, value_metadata|
                Datapoint.create(
                    :metric => metrics_by_target['load_balancer'],
                    :instance => dummy_i,
                    :loadBalancer => lb,
                    :timestamp => timestamp,
                    :period => period,
                    :value => value_metadata[:computed_value],
                )
            end
        end

        # save instance data
        data_aggregated[:load_balancers].each do |lb, lb_metadata|
            return if lb_metadata[:instances].nil? # proceed to save instance data only for EC2 metrics
            lb_metadata[:instances].each do |i, i_metadata|
                i_metadata[:instance_data].each do |timestamp, value_metadata|
                    Datapoint.create(
                        :metric => metrics_by_target['instance'],
                        :instance => i,
                        :loadBalancer => lb,
                        :timestamp => timestamp,
                        :period => period,
                        :value => value_metadata[:computed_value],
                    )
                end
            end
        end
    end
end
