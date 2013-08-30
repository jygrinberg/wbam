function ChartCanvasManager(chart_canvas_id, rows, cols) {
    this.canvas = $("#" + chart_canvas_id);
    this.rows = Math.max(rows, 1);
    this.cols = Math.max(cols, 1);

    this.min_well_height = 500;
    this.min_well_width = 725;
    this.min_wrapper_height = 150;
}

ChartCanvasManager.prototype.createChartFormManagers = function() {
    var chartCanvasManager = this;
    $.ajax({
        type: "GET",
        url: "/analyze/get_metric_data",
        dataType: "JSON"
    }).success(
        function (json) {
            chartCanvasManager.metric_data = json["metric_data"]
            for (var i = 0; i < chartCanvasManager.rows * chartCanvasManager.cols; i++) {
                new ChartFormManagers(i);
            }
        }
    );
    return false;
}

ChartCanvasManager.prototype.resizeCharts = function() {
    var chart_well = $(".chart-well");
    var chart_well_vertical_edges =
        ( parseInt(chart_well.css('marginBottom'))
            + parseInt(chart_well.css('marginTop'))
            + parseInt(chart_well.css('borderBottom'))
            + parseInt(chart_well.css('borderTop'))
            + parseInt(chart_well.css('paddingBottom'))
            + parseInt(chart_well.css('paddingTop')) );
    var chart_well_horizontal_edges =
        ( parseInt(chart_well.css('marginLeft'))
            + parseInt(chart_well.css('marginRight'))
            + parseInt(chart_well.css('borderLeft'))
            + parseInt(chart_well.css('borderRight'))
            + parseInt(chart_well.css('paddingLeft'))
            + parseInt(chart_well.css('paddingRight')) );

    // set chart-well width
    var well_width = this.canvas.width()
        - parseInt(this.canvas.css('marginLeft'))
        - parseInt(this.canvas.css('marginRight'))
        - 17; // width of scrollbar

    well_width /= this.cols; 	// # of chart cols
    var chart_well_horizontal_edges =
        ( parseInt(chart_well.css('marginLeft'))
            + parseInt(chart_well.css('marginRight'))
            + parseInt(chart_well.css('borderLeft'))
            + parseInt(chart_well.css('borderRight'))
            + parseInt(chart_well.css('paddingLeft'))
            + parseInt(chart_well.css('paddingRight')) );
    well_width -= chart_well_horizontal_edges;
    well_width = Math.max(well_width, this.min_well_width);
    chart_well.width(well_width + "px");

    // set chart-well height
    var well_height = document.documentElement.clientHeight - $("#page-container").offset().top - 2; // height below navbar
    well_height /= this.rows;
    well_height -= chart_well_vertical_edges;
    well_height = Math.max(well_height, this.min_well_height);
    chart_well.height(well_height + "px");

    // set chart-wrapper height
    var wrapper_height = well_height;
    if (chart_well.find(".axis-form").css('display') != 'none') wrapper_height -= $(".axis-form").outerHeight();
    wrapper_height = (wrapper_height <= 20)? 0 : wrapper_height;
    wrapper_height -= 20; //   <==>   $(".chart-title-container").outerHeight();
    if (wrapper_height >= this.min_wrapper_height) {
        $(".chart-wrapper").show(0);
        $(".chart-wrapper").height(wrapper_height + "px");
    } else {
        $(".chart-wrapper").hide(0);
    }

    // position chart-load-spinner
    chart_well.find(".chart-load-spinner").css('top', (wrapper_height/2 - 20 + "px")); // '-20' to account for the chart title's height (approximate)
}

ChartCanvasManager.prototype.displayChart = function(chart_number) {
    $.ajax({
        type: "GET",
        url: "/dashboard_manager/get_chart_settings",
        data: { chart_number: chart_number },
        dataType: "JSON"
    }).success(
        function (json) {
            var chart_settings = json;
            var form = $("#axis-form-" + chart_number);

            // load the form settings
            form.find('.target').val(chart_settings["target"]+'');

            form.find('.chart-start-time').val(chart_settings["start_time"]+'');
            form.find('.chart-end-time').val(chart_settings["end_time"]+'');
            form.find('.chart-interval').val(chart_settings["interval"]+'');

            form.find('.x-metric-name').val(chart_settings["x_metric_name"]+'');
            form.find('.x-data-type').val(chart_settings["x_data_type"]+'');
            form.find('.x-axis-min').val(chart_settings["x_axis_min"]+'');
            form.find('.x-axis-max').val(chart_settings["x_axis_max"]+'');

            form.find('.y-metric-name').val(chart_settings["y_metric_name"]+'');
            form.find('.y-data-type').val(chart_settings["y_data_type"]+'');
            form.find('.y-axis-min').val(chart_settings["y_axis_min"]+'');
            form.find('.y-axis-max').val(chart_settings["y_axis_max"]+'');

            form.find(".axis-metric-name").trigger("change");

            form.find('.toggle_chart_type button[value=' + chart_settings['chart_type'] + ']').click();
            form.find('.toggle_color button[value=' + chart_settings['color'] + ']').click();
            form.find('.toggle_size button[value=' + chart_settings['size'] + ']').click();

            // generate the graph
            form.trigger("submit");
        }
    );
}

ChartCanvasManager.prototype.loadDashboardCharts = function () {
    for (var i=0; i < this.rows * this.cols; i++) {
        this.displayChart(i);
    }
}

