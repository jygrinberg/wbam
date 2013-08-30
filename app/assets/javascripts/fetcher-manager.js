function FetcherManager() {
    var refresh_interval_sec = 10;

    var load_recent_data_fetches = function() {
        $.ajax({
            type: "GET",
            url: "/data/get_fetchers",
            dataType: "JSON"
        }).success(function(json) {
                var current_time = json["current_time"]
                $('.running-fetchers-last-updated').text('Last updated: ' + current_time);

                var data_fetchers = json["data_fetchers"];
                var data_fetchers_table = $("#data-fetchers-table tbody");
                data_fetchers_table.find('tr:gt(0)').remove();
                for (var i=0; i<data_fetchers.length; i++) {
                    var data_fetcher = data_fetchers[i]
                    data_fetchers_table.append($('<tr style="display:none">')
                        .append($('<td>')
                            .text(data_fetcher["id"])
                        )
                        .append($('<td>')
                            .text(data_fetcher["fetch_count"])
                        )
                        .append($('<td>')
                            .text(data_fetcher["fetch_timestamp"])
                        )
                        .append($('<td>')
                            .text(data_fetcher["time_range"])
                        )
                        .append($('<td>')
                            .text(data_fetcher["repeat_frequency"])
                        )
                        .append($('<td>')
                            .text(data_fetcher["status"])
                        )
                    );
                }

                data_fetchers_table.find('tr:gt(0)').show('medium');

                var beanstalk_fetchers = json["beanstalk_fetchers"];
                var beanstalk_fetchers_table = $("#beanstalk-fetchers-table tbody");
                beanstalk_fetchers_table.find('tr:gt(0)').remove();
                for (var i=0; i<beanstalk_fetchers.length; i++) {
                    var beanstalk_fetcher = beanstalk_fetchers[i]
                    beanstalk_fetchers_table.append($('<tr style="display:none">')
                        .append($('<td>')
                            .text(beanstalk_fetcher["id"])
                        )
                        .append($('<td>')
                            .text(beanstalk_fetcher["fetch_count"])
                        )
                        .append($('<td>')
                            .text(beanstalk_fetcher["fetch_timestamp"])
                        )
                        .append($('<td>')
                            .text(beanstalk_fetcher["repeat_frequency"])
                        )
                        .append($('<td>')
                            .text(beanstalk_fetcher["status"])
                        )
                    );
                }

                beanstalk_fetchers_table.find('tr:gt(0)').show('medium');
            });
        return false; // prevents normal behavior
    };

    $('#get-data-form').each(function() {
        $(this).bind('submit', function () {
            load_recent_data_fetches();
        });

//        $(this).submit(function () {
//            var formValues = $(this).serialize();
//            $.ajax({
//                type: "GET",
//                url: "/alarm_manager/create_alarm",
//                data: formValues,
//                dataType: "JSON"
//            }).success(function(json) {
//                    var alarm = json["alarm_stats"]
//                    var alarms_table = $("#alarms-table tbody")
//                    alarms_table.append($('<tr style="display:none">')
//                        .append($('<td>')
//                            .text(alarm["metric_name"])
//                        )
//                        .append($('<td>')
//                            .text(alarm["data_type"])
//                        )
//                        .append($('<td>')
//                            .text(alarm["interval"])
//                        )
//                        .append($('<td>')
//                            .text(alarm["trigger_condition"])
//                        )
//                        .append($('<td>')
//                            .text(alarm["status"])
//                        )
//                    );
//                    alarms_table.find('tr:gt(0)').show('medium');
//                });
//            return false;
//        });
    });

    $(document).ready(function() {
        load_recent_data_fetches();
        setInterval(function(){
            load_recent_data_fetches();
        }, refresh_interval_sec*1000);
    });
}