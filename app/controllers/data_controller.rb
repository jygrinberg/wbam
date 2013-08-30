class DataController < ApplicationController

    def index
        @metrics = Metric.all
        @metrics_distinct = Metric.all.distinct.pluck(:metric_name, :data_type, :namespace).map { |m| {metric_name: m[0], data_type: m[1], namespace: m[2] } }
        #@health_stats = get_current_health
    end

    def get_current_health
        period = 300

        health_stats = {}

        LoadBalancer.where('name != "N/A"').each_with_index do |loadBalancer, i|

            service_stats = []

            @metrics_distinct.each do |m|
                metric = Metric.where(metric_name: m[:metric_name], data_type: m[:data_type], target: 'load_balancer').first
                dp = Datapoint.where(loadBalancer_id: loadBalancer, period: period, metric_id: metric).order('timestamp').last

                next if dp.nil?

                count = Datapoint.where(loadBalancer_id: loadBalancer, period: period, metric_id: metric).count
                percentile = (Datapoint.where(loadBalancer_id: loadBalancer, period: period, metric_id: metric).where('value < ?', dp.value).count.to_f) / count * 100

                metric_stats = {}

                metric_stats[:metric] = metric
                metric_stats[:dp] = dp
                metric_stats[:percentile] = percentile
                metric_stats[:status] = percentile > 90? 1 : 0

                service_stats << metric_stats
            end

            service_stats.sort_by! { |m| -m[:status] }

            health_stats[loadBalancer.title.to_sym] = service_stats
        end

        return (health_stats.nil?)? Hash.new : health_stats
    end

    def launch_data_fetcher
        df = DataFetcher.create(start_min_ago: params[:start_min_ago].to_i, end_min_ago: params[:end_min_ago].to_i, repeat_frequency_sec: params[:repeat_frequency_sec].to_i)
        df.delay.fetch_cloudwatch_data

        render text: ''
        return false
    end

    def launch_beanstalk_fetcher
        bf = BeanstalkFetcher.create(repeat_frequency_sec: params[:repeat_frequency_sec].to_i)
        bf.delay.fetch_running_beanstalks

        render text: ''
        return false
    end

    def repair_database
        # render 'index'
        df = DataFetcher.create
        df.fetch_cloudwatch_data

        #bf = BeanstalkFetcher.create(repeat_frequency_sec: 0)
        #bf.fetch_running_beanstalks

        render text: 'DB repair not yet implemented'
        return false
    end

    def get_fetchers
        current_time = Time.now.utc.strftime(Settings[:time_format_seconds])
        data_fetchers = DataFetcher.all.order('started_fetch_at DESC')
        data_fetchers_stats = get_fetcher_stats(data_fetchers, true)

        beanstalk_fetchers = BeanstalkFetcher.all.order('started_fetch_at DESC')
        beanstalk_fetchers_stats = get_fetcher_stats(beanstalk_fetchers, false)

        render json: {data_fetchers: data_fetchers_stats, beanstalk_fetchers: beanstalk_fetchers_stats, current_time: current_time}
    end

    private
    def get_fetcher_stats(fetchers, include_time_range)
        fetchers.map do |fetcher|
            status = 'Done'
            status += ' (sleeping for ' + fetcher.repeat_frequency_sec.to_s + ' sec until next fetch)' unless fetcher.repeat_frequency_sec == 0
            status = 'Running...' if fetcher.completed_fetch_at.nil?
            status = 'Initializing...' if fetcher.started_fetch_at.nil?

            fetch_timestamp = (fetcher.started_fetch_at.nil?)? 'Not started' : fetcher.started_fetch_at.strftime(Settings[:time_format_seconds])
            repeat_frequency = (fetcher.repeat_frequency_sec == 0)? 'Once' : fetcher.repeat_frequency_sec.to_s + ' sec'
            fetcher_stats =
                {
                    fetch_timestamp: fetch_timestamp,
                    repeat_frequency: repeat_frequency,
                    status: status,
                    id: fetcher.id,
                    fetch_count: fetcher.fetch_count
                }
            fetcher_stats[:time_range] = 'Past ' + fetcher.start_min_ago.to_s + ' min'  if include_time_range
            fetcher_stats
        end
    end
end
