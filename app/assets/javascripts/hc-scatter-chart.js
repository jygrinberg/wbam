var HCScatterChart = function (data, chart_id, chart_title, chart_subtitle, x_label, y_label, x_range, y_range) {
    var chart = $('#' + chart_id);

    if (chart.highcharts() != null && chart.highcharts() != undefined) {
        chart.highcharts().destroy();
        console.log('Highchart destroyed');
    }

    chart.highcharts({
        chart: {
            type: 'scatter',
            zoomType: 'xy',
            marginTop: 70,
            events: {
                load: function(event) {
                    // TODO figure out how to select only the latest dp
                    var dps = $('#' + chart_id).find('.highcharts-markers path');

//                    dps.bind('fade-cycle', function() {
//                        $(this).fadeOut('fast', function() {
//                            $(this).fadeIn('fast', function() {
//                                $(this).trigger('fade-cycle');
//                            });
//                        });
//                    });
//
//                    dps.each(function(index, elem) {
//                        setTimeout(function() {
//                            $(elem).trigger('fade-cycle');
//                        }, 0);
//                    });
                }
            }
        },
        title: {
            text: chart_title,
            style: {
                fontWeight: 'bold',
                fontSize: '30px',
                color: '#333333'
            }
        },
        subtitle: {
            text: chart_subtitle,
            floating: true,
            align: 'left',
            verticalAlign: 'top',
            y: 34,
            x: 10,
            style: {
                fontSize: '14px',
                color: '#333333'
            }
        },
        xAxis: {
            title: {
                text: x_label,
                style: {
                    fontSize: '16px',
                    color: '#333333'
                }
            },
            min: x_range.min,
            max: x_range.max
        },
        yAxis: {
            title: {
                text: y_label,
                style: {
                    fontSize: '16px',
                    color: '#333333'
                }
            },
            min: y_range.min,
            max: y_range.max
        },
        plotOptions: {
            scatter: {
                turboThreshold: 0,
                tooltip : {
                    crosshairs: [true, true],
                    useHTML: true,
                    headerFormat: '<b>{series.name}</b><br>',
                    pointFormat: '{point.timestamp}<br>x: <b>{point.x}</b><br>y: <b>{point.y}</b>',
                    valueDecimals: 2
                }
            },
            series: {
                stickyTracking: false
            }
        },
        series: data
    });

}


