function ChartFormManagers(form_id_number) {
    this.form = $("#axis-form-" + form_id_number);
    this.chart_load_spinner = $('#chart-load-spinner-' + form_id_number);

    var form_id_number = form_id_number;
    var form = this.form;
    var chart_load_spinner = this.chart_load_spinner;
    var disabled_font_color = "#eeeeee";
    var enabled_font_color = "#555555"
    var axis_form_manager = this

    var spinner_opts = {
        lines: 13, // The number of lines to draw
        length: 20, // The length of each line
        width: 10, // The line thickness
        radius: 22, // The radius of the inner circle
        corners: 1, // Corner roundness (0..1)
        rotate: 0, // The rotation offset
        direction: 1, // 1: clockwise, -1: counterclockwise
        color: '#000', // #rgb or #rrggbb
        speed: 1.7, // Rounds per second
        trail: 70, // Afterglow percentage
        shadow: false, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 30, // The z-index (defaults to 2000000000)
        top: 'auto', // Top position relative to parent in px
        left: 'auto' // Left position relative to parent in px
    };

    form.find(".toggle_chart_type button").each(function () {
        // bind the toggle_chart_type radio buttons to the hidden field
        $(this).bind('click', function () {
            form.find(".toggle_chart_type input[type=hidden]").val($(this).val());
            var x_axis_form_fields = form.find(".x-axis-settings td").children();
            if ($(this).val() == "line" || $(this).val() == "bar") {
                x_axis_form_fields.attr("disabled", true);
                x_axis_form_fields.css("color", disabled_font_color); // bootstrap-defined
            }
            else {
                x_axis_form_fields.attr("disabled", false);
                x_axis_form_fields.css("color", enabled_font_color); // bootstrap-defined
            }
        });
    });

    form.find(".toggle_color button").each(function () {
        // bind the toggle_color radio buttons to the hidden field
        $(this).bind('click', function () {
            form.find(".toggle_color input[type=hidden]").val($(this).val());
        });
    });

    form.find(".toggle_size button").each(function () {
        // bind the toggle_size radio buttons to the hidden field
        $(this).bind('click', function () {
            form.find(".toggle_size input[type=hidden]").val($(this).val());
        });
    });

    $(document).ready(function () {
        axis_form_manager.spinner = new Spinner(spinner_opts).spin();
        chart_load_spinner.append(axis_form_manager.spinner.el);
        form.find(".btn-group").children().first().click();
        form.find(".axis-metric-name").trigger("change");
    });

    form.find(".axis-metric-name").change(function (e) {
        form.axis_updated = $(e.target).parents("tr");
        var metric_name = $(this).val()
        var data_types = window.chartCanvasManager.metric_data[metric_name]['data_types'];
        var data_type_field = form.axis_updated.find(".axis-data-type");
        data_type_field.empty();
        for (var i = 0; i < data_types.length; i++) {
            data_type_field.append('<option value=' + data_types[i] + '>' + data_types[i] + '</option>');
        }
        return false;
    });

    form.submit(function() {
        var chart = $("#chart-" + form_id_number);
        var start = (new Date()).getTime() / 1000;
        console.log(form_id_number + " start: " + start);

        $(axis_form_manager.spinner.el).show();
        chart.css('opacity', 0.5);

        var formValues = $(this).serialize();
        formValues += "&timestamp=" + (new Date()).getTime();
        $.ajax({
            type: "GET",
            url: "/analyze/generate",
            data: formValues,
            dataType: "JSON"
        }).success(function(json) {
                console.log(form_id_number + " got data: " + ((new Date()).getTime()/1000 - start));
                var data = jQuery.parseJSON(json["data"]);
                var chart_type = json["chart_type"];
                var chart_title = json["chart_title"];
                var chart_subtitle = json["chart_subtitle"];
                var x_axis_title = json["x_axis_title"];
                var y_axis_title = json["y_axis_title"];
                var x_axis_range = json["x_axis_range"];
                var y_axis_range = json["y_axis_range"];
                var alarm_failed = json["alarm_failed"];

//                chart.find('*').not('.spinner').remove();

                window.chartCanvasManager.resizeCharts();

                $(axis_form_manager.spinner.el).hide();
                chart.css('opacity', 1);

                if (!data || data[0] == undefined || data[0]["data"] == undefined || data[0]["data"].length == 0) return;

                if (alarm_failed)   chart.closest('.chart-well').css('background-color', 'red');
                else                chart.closest('.chart-well').css('background-color', '');

                if (chart_type == 'line') 	        HCLineChart(data, chart.attr('id'), chart_title, chart_subtitle, x_axis_title, y_axis_title, x_axis_range, y_axis_range);
                else if (chart_type == 'bar') 	    HCBarChart(data, chart.attr('id'), chart_title, chart_subtitle, x_axis_title, y_axis_title, x_axis_range, y_axis_range);
                else if (chart_type == 'scatter') 	HCScatterChart(data, chart.attr('id'), chart_title, chart_subtitle, x_axis_title, y_axis_title, x_axis_range, y_axis_range);

                console.log(form_id_number + " end1: " + ((new Date()).getTime()/1000 - start));

            });
        return false; // prevents normal behavior
    });
}
