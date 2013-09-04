class DataController < ApplicationController

    def index
        @metrics = Metric.all
        @metrics_distinct = Metric.all.distinct.pluck(:metric_name, :data_type, :namespace).map { |m| {metric_name: m[0], data_type: m[1], namespace: m[2] } }
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
