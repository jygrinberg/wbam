class BeanstalkFetcher < ActiveRecord::Base
    attr_accessible :started_fetch_at, :completed_fetch_at, :repeat_frequency_sec, :fetch_count

    DEFAULT_REPEAT_FREQUENCY_SEC = 30
    NO_REPEAT_SIGNAL = 0

    after_initialize :default_values

    def default_values
        self.repeat_frequency_sec ||= DEFAULT_REPEAT_FREQUENCY_SEC
        self.fetch_count ||= 0
        return true
    end

    def fetch_running_beanstalks
        self.started_fetch_at = Time.now.utc
        self.completed_fetch_at = nil
        self.save

        running_instances = Instance.where('stopped_at IS NULL').to_a

        Settings.aws.accounts.each do |aws_account|
            AWS.config(access_key_id: aws_account.access_key_id, secret_access_key: aws_account.secret_access_key, region: aws_account.region)
            elb = AWS::ELB.new
            elb.load_balancers.each do |lb_metadata|
                lb = LoadBalancer.find_by_name(lb_metadata.name)
                lb = LoadBalancer.new(name: lb_metadata.name, zone: lb_metadata.availability_zone_names.to_s) if lb.nil?
                lb_metadata.instances.each do |instance_metadata|
                    i = Instance.find_by_name(instance_metadata.id)
                    service_title = instance_metadata.tags.to_h['Name']
                    i = Instance.new(name: instance_metadata.id, zone: instance_metadata.availability_zone, title: service_title, loadBalancer: lb) if i.nil?
                    i.loadBalancer = lb if i.loadBalancer.nil? || i.loadBalancer != lb
                    if instance_metadata.status.to_s == 'running' then
                        i.stopped_at = nil
                        running_instances -= [i] if running_instances.include? i
                    else
                        i.stopped_at =  self.started_fetch_at
                    end
                    i.save
                    lb.title = service_title if lb.title.nil? || lb.title != service_title
                end
                lb.save
            end
        end

        # mark previously running instances as stopped
        running_instances.each { |i| i.update_attributes(:stopped_at => self.started_fetch_at) }

        self.completed_fetch_at = Time.now.utc
        self.fetch_count = self.fetch_count + 1
        self.save

        unless self.repeat_frequency_sec == NO_REPEAT_SIGNAL then
            wait_sec = self.started_fetch_at + self.repeat_frequency_sec.seconds - Time.now.utc
            wait_sec = 0 if wait_sec < 0
            delay({:run_at => wait_sec.seconds.from_now}).fetch_running_beanstalks
        end
    end

end
