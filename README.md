WBAM: Web-Based Application Monitor
====
WBAM is a tool to monitor the health of web applications hosted on Amazon Web Services. Using raw data from Amazon CloudWatch, it computes and displays important health metrics to help users visualize emerging patterns and react immediately in case something goes wrong. WBAM has three components: 

* Data Fetcher: background service to fetch, analyze, and store data in an internal database
* Charting Canvas: highly interactive charting tool to create colorful dashboards for large display screens and for in-depth analyses
* Alarm Manager: summary of the website's current health to alert users about key metric outliers

Set Up
===
Required technology:
* Rails (recommended: 4.0.0)
* Ruby (recommended 1.9.3)
* AWS Account 
 
Steps:
* Fork WBAM repo
* Create MySQL databases (default: 'wbam_dev', 'wbam_test', 'wbam_prod')
* Create MySQL user with read/write permissision (default: username 'wbam' password 'wbam')
* Update /config/database.yml if used database names, user names, or user passwords other than defaults
* Update /config/settings.yml with AWS access key id, secret access key, and region
* Run 'bundle install' to install missing gems
* Run 'rake db:migrate' to create database tables
* Run 'rake db:seed' to seed database 
* Run 'rake jobs:work' to spawn background process for continuous data fetching
* Run 'rails server' to start server
* Navigate to localhost:3000
* In the "Database" tab, launch a Beanstalk Fetcher (recommended -- repeat frequency: 30 sec)
* In the "Database" tab, launch a Data Fetcher (recommended -- start time: 5 min ago, end time: now, repeat frequency: 3 min)
* In the "Alarms" tab, create alarms
* In the "Charts" tab, create charts


Data Fetcher
===
In the "Database" tab, WBAM users can launch a beanstalk fetcher to track the running load balancers and server instances at each timestamp, and a data fetcher to continouously fetch metric data for each running beanstalk. A dynamic user interface allows WBAM users to monitor that status of all running beanstalk and data etchers. 

<b>Note:</b> in order to start running the fetchers once they are created, execute 'rake jobs:work' in the command line to spawn a background process. To terminate this process, execute 'rake jobs:clear'.

Each time a data fetcher executes, it makes requests for each metric name (CPU utilization, network traffic, request count, etc.), each data type (maximum, average, etc.), each interval (past minute, 5 minutes, hour, day, etc.), and each instance of each load balancer.

Some metrics pertain to instances (i.e. CPU utilization) whereas some pertain to load balancers (i.e. latency). In order to determine instance-specific metric data for load balancers, WBAM aggregates data for each load balancer’s instances. Since instances can start and stop at any time, determining a load balancer's instances at every timestamp can be extremely computationally expensive. 

Charting Canvas
===
In the "Chart" tab, WBAM users can create chart dashboards. Each chart form lets users specify their desired chart type (line, bar, or scatter), target (which instances and load balancers to plot), time range (start, stop, and interval), metric name, and data type. In order to highlight outliers, users can choose to color and/or size data points based on their values, or their timestamps. Users can also fix the ranges of the axes so that small deviations from the norm do not appear large. 

By clicking the settings button, users can specify how many charts to display at a time, and they can turn “Presenter Mode” on so the charts reload every minute with the latest data. Turning "Alarm Mode" on emphasizes datapoints and charts that trigger alarms (created in the "Alarms" tab). Users can save their dashboard for later use, and they can create new ones to cycle through multiple chart screens. 

One of the mroe complex charting features is the scatter plot, which allows users to plot two metrics against each other. (Line and bar charts plot one metric over time.) Consider a user who wants to plot network traffic against latency for each load balancer, averaged over each 5 minute interval, over the past week. Since network traffic is an instance-specific metric, WBAM needs to extract the data points that were averaged over each load balancer’s instances at each 5 minute interval, then pair each data point with the average latency for its corresponding load balancer at the corresponding time interval. If users want to color or size data points based on value or time, WBAM also needs to determine where each data point falls in the value range or time range then compute the RGB color components or size in pixels accordingly. Since these charts may render 10,000 data points or more, the database is indexed by metric, instance, load balancer, aggregate level, and timestamp. Scatter plots is one feature that sets WBAM apart from other website monitors because it helps user visualize patterns that are otherwise surprisingly hard to detect.

Alarm Manager
===
In the "Alarms" tab, WBAM users can customize alarms for each metric type. A colorful table summarizes the health status of each load balancer for each alarm, and it is dynamically updated so it can be put on display.
