WBAM: Web-Based Application Monitor
====
WBAM is a tool to monitor the health of web applications hosted on Amazon Web Services. Using raw data from Amazon CloudWatch, it computes and displays important health metrics to help users visualize emerging patterns and react immediately in case something goes wrong. WBAM has three components: 

* Data Fetcher: background service to fetch, analyze, and store data in an internal database
* Charting Canvas: highly interactive charting tool to create colorful dashboards for large display screens and for in-depth analyses
* Alarm Manager: summary of the website's current health to alert users about key metric outliers

Data Fetcher
===
In the "Database" tab, WBAM users can launch a beanstalk fetcher to track the running load balancers and server instances at each timestamp, and a data fetcher to continouously fetch metric data for each running beanstalk. A dynamic user interface allows WBAM users to monitor that status of all running beanstalk and data etchers. Note: once the fetchers are created, execute 'rake jobs:work' in the command line to start running them in a bacground process. To abort this process, execute 'rake jobs:clear'.

Each time a data fetcher executes, it makes requests for each metric name (CPU utilization, network traffic, request count, etc.), each data type (maximum, average, etc.), each interval (past minute, 5 minutes, hour, day, etc.), and each instance of each load balancer.

Some metrics pertain to instances (i.e. CPU utilization) whereas some pertain to load balancers (i.e. latency). In order to determine instance-specific metric data for load balancers, WBAM aggregates data for each load balancer’s instances. Since instances can start and stop at any time, determining a load balancer's instances at every timestamp can be extremely computationally expensive. 
