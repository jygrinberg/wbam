# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
metrics =
    [
        {metric_name: 'NetworkIn', namespace: 'AWS/EC2', data_type: 'Average', unit:'Bytes'},
        {metric_name: 'NetworkIn', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Bytes'},
        {metric_name: 'NetworkOut', namespace: 'AWS/EC2', data_type: 'Average', unit:'Bytes'},
        {metric_name: 'NetworkOut', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Bytes'},
        {metric_name: 'CPUUtilization', namespace: 'AWS/EC2', data_type: 'Average', unit:'Percent'},
        {metric_name: 'CPUUtilization', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Percent'},
        {metric_name: 'DiskReadBytes', namespace: 'AWS/EC2', data_type: 'Average', unit:'Bytes'},
        {metric_name: 'DiskWriteBytes', namespace: 'AWS/EC2', data_type: 'Average', unit:'Bytes'},
        {metric_name: 'DiskReadBytes', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Bytes'},
        {metric_name: 'DiskWriteBytes', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Bytes'},
        {metric_name: 'DiskReadOps', namespace: 'AWS/EC2', data_type: 'Average', unit:'Count'},
        {metric_name: 'DiskWriteOps', namespace: 'AWS/EC2', data_type: 'Average', unit:'Count'},
        {metric_name: 'DiskReadOps', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Count'},
        {metric_name: 'DiskWriteOps', namespace: 'AWS/EC2', data_type: 'Maximum', unit:'Count'},
        {metric_name: 'Latency', namespace: 'AWS/ELB', data_type: 'Average', unit:'Seconds'},
        {metric_name: 'RequestCount', namespace: 'AWS/ELB', data_type: 'Sum', unit:'Count'},
        {metric_name: 'HTTPCode_Backend_2XX', namespace: 'AWS/ELB', data_type: 'Sum', unit:'Count'},
        {metric_name: 'HTTPCode_Backend_5XX', namespace: 'AWS/ELB', data_type: 'Sum', unit:'Count'},
    ]

metrics.each do |metric|
    if metric[:namespace] == 'AWS/EC2' then
        Metric.create(
            metric_name: metric[:metric_name],
            namespace: metric[:namespace],
            data_type: metric[:data_type],
            unit: metric[:unit],
            target: 'instance')
    end

    Metric.create(
        metric_name: metric[:metric_name],
        namespace: metric[:namespace],
        data_type: metric[:data_type],
        unit: metric[:unit],
        target: 'load_balancer')

    Metric.create(
        metric_name: metric[:metric_name],
        namespace: metric[:namespace],
        data_type: metric[:data_type],
        unit: metric[:unit],
        target: 'website_total')
end

lb_na = LoadBalancer.create(zone: 'N/A', name: 'N/A', title:'Multiple Load Balancers') 	            # dummy loadBalancer for website_total datapoints
i_na = Instance.create(zone: 'N/A', name: 'N/A', title:'Multiple Instances', loadBalancer: lb_na) 	# dummy instance for load_balancer datapoints
Dashboard.create(name: 'Guidewire Live', rows: '1', cols: '2')
