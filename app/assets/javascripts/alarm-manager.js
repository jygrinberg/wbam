function AlarmManager(alarms_canvas, num_lbs) {
    var alarm_canvas = $('.' + alarms_canvas);
    var num_lbs = num_lbs;

    var refresh_interval_sec = 60;

    var resize_canvas = function () {
        var alarm_canvas_horizontal_edges =
            ( parseInt(alarm_canvas.css('marginLeft'))
                + parseInt(alarm_canvas.css('marginRight'))
                + parseInt(alarm_canvas.css('borderLeft'))
                + parseInt(alarm_canvas.css('borderRight'))
                + parseInt(alarm_canvas.css('paddingLeft'))
                + parseInt(alarm_canvas.css('paddingRight'))
                + 17); // width of scrollbar

        var container_width = alarm_canvas.parent().width();
        alarm_canvas.width((container_width - alarm_canvas_horizontal_edges) + "px");
    }

    $(".create-alarm-form .metric-name-input").change(function () {
        var metric_name = $(this).val();
        var data_types = self.metric_data[metric_name]['data_types'];
        var data_type_field = $(".data-type-input");
        data_type_field.empty();
        for (var i = 0; i < data_types.length; i++) {
            data_type_field.append('<option value=' + data_types[i] + '>' + data_types[i] + '</option>');
        }

       $('.alarm-threshold-units').text(self.metric_data[metric_name]['unit_pretty']);

        return false;
    });

    var load_alarms = function () {
        $.ajax({
            type: "GET",
            url: "/alarm_manager/get_alarms",
            dataType: "JSON"
        }).success(function (json) {
                if (num_lbs != json["num_lbs"]) {
                    window.location.reload();
                }
                var current_time = json["current_time"];
                $('.alarms-last-updated').text('Last updated: ' + current_time);

                var alarms_stats = json["alarms_stats"];
                var alarm_canvas = $("#alarms-table tbody");

                alarm_canvas.find('tr:gt(0) td').css('visibility', 'hidden');

                for (var i = 0; i < alarms_stats.length; i++) {
                    var alarm_stats = alarms_stats[i];
                    var alarm_id = alarm_stats["alarm_id"];
                    var stats_by_lb = alarm_stats["alarm_stats"];
                    var stats_row = alarm_canvas.find("#alarm-stats-" + alarm_id);

                    for (var j = 0; j < stats_by_lb.length; j++) {
                        var stats_for_lb = stats_by_lb[j];
                        var lb_stats_td = stats_row.find("td.stats-lb-" + stats_for_lb["lb_name"]);
                        if (stats_for_lb["status"] == 'OK') {
                            lb_stats_td.html('OK');
                            lb_stats_td.addClass('alarm-pass');
                            lb_stats_td.removeClass('alarm-fail');
                        } else {
                            if (stats_for_lb["message"].indexOf('100%') != -1) {
                                lb_stats_td.html('<span class="alarm-fail-status">' + '<span style="display:none">' + 'EPIC' + '</span>' + stats_for_lb["status"] + '</span><br>' + stats_for_lb["message"]);
                            } else {
                                lb_stats_td.html('<span class="alarm-fail-status">' + stats_for_lb["status"] + '</span><br>' + stats_for_lb["message"]);
                            }
                            lb_stats_td.addClass('alarm-fail');
                            lb_stats_td.removeClass('alarm-pass');
                        }
                    }
                }

                alarm_canvas.find('tr:gt(0) td').css('visibility', 'visible');
            });
        return false; // prevents normal behavior
    };

    $('tr.alarm-stats').hover(
        function() {
            $(this).find('.remove-alarm').show();
        },
        function() {
            $(this).find('.remove-alarm').hide();
        }
    );

    $('.remove-alarm').click(function (e) {
        var alarm_id = $(this).val();
        var alarm_stats = $(this).closest('tr.alarm-stats');
        $.ajax({
            type: "GET",
            url: "/alarm_manager/remove_alarm",
            data: { alarm_id: alarm_id},
            dataType: "HTML"
        }).success(
            function (html) {
                alarm_stats.remove();
            }
        );
        return false;
    });

    $('#create-alarm-form').submit(function () {
        var formValues = $(this).serialize();
        $.ajax({
            type: "GET",
            url: "/alarm_manager/create_alarm",
            data: formValues,
            dataType: "HTML"
        }).success(function (html) {
                window.location.reload();
//                if (num_lbs != json["num_lbs"]) {
//                    window.location.reload();
//                }
//                var alarm_description = json["alarm_description"];
//                var alarm_stats = json["alarm_stats"];
//                var alarm_id = alarm_stats["alarm_id"];
//
//                var alarm_canvas = $("#alarms-table tbody")
//
//                alarm_canvas.append($('<tr class="alarm-header">')
//                    .append($('<td colspan='+num_lbs+'>')
//                        .text(alarm_description)
//                    )
//                );
//
//                alarm_canvas.append($('<tr class="row-bordered alarm-stats" id="alarm-stats-'+alarm_id+'">'));
//                var stats_row = alarm_canvas.find("#alarm-stats-" + alarm_id);
//                var stats_by_lb = alarm_stats["alarm_stats"];
//
//                for (var j = 0; j < stats_by_lb.length; j++) {
//                    var stats_for_lb = stats_by_lb[j];
//                    var lb_stats_td = stats_row.append($('<td class="stats-lb-'+stats_for_lb["lb_name"]+'"><span style="visibility:hidden">' )
//                        .text(stats_for_lb["status"])
//                    );
//                    if (stats_for_lb["status"] == 'OK') {
//                        lb_stats_td.css('background-color', 'rgb(173,255,47)');
//                        lb_stats_td.addClass('alarm-pass');
//                    } else {
//                        lb_stats_td.css('background-color', 'rgb(255,69,0)');
//                        lb_stats_td.removeClass('alarm-fail');
//                    }
//                }
//
            });
        return false;
    });

    $(document).ready(function () {
        resize_canvas();
        $.ajax({
            type: "GET",
            url: "/analyze/get_metric_data",
            dataType: "JSON"
        }).success(
            function (json) {
                self.metric_data = json["metric_data"]
                $(".create-alarm-form .metric-name-input").trigger('change');
            }
        );
        load_alarms();

        setInterval(function () {
//            load_alarms();
            window.location.reload();
        }, refresh_interval_sec * 1000);
    });

    $(document).resize(function () {
        resize_canvas();
    });
}