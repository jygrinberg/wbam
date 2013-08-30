wbam
====

Web-Based Application Monitor

Description:
===
WBAM is a tool to monitor the health of web applications hosted on Amazon Web Services. Using raw data from Amazon CloudWatch, it computes and displays important health metrics so users can react immediately when something goes wrong. WBAM has three components: 

* Data Fetcher: background service to fetch, analyze, and store data in an internal database
* Charting Canvas: highly interactive charting tool to create colorful dashboards for in-depth analyses and large displays screens
* Alarm Manager: summary of the website's current health to alert users about key metric outliers
