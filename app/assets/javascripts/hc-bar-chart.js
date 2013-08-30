var HCBarChart = function (data, chart_id, chart_title, chart_subtitle, x_label, y_label, x_range, y_range) {
    var chart = $('#' + chart_id);

    if (chart.highcharts() != null && chart.highcharts() != undefined) {
        chart.highcharts().destroy();
        console.log('Highchart destroyed');
    }

    chart.highcharts({
    chart: {
        type: 'column',
        marginTop: 70,
        zoomType: 'x',
        animation: false
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
        type: 'datetime',
        title: {
            enabled: false
        }
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
        series: {
            fillOpacity: 0.2,
            borderWidth: 2,
            borderColor: 'black',
            animation: false,
            stickyTracking: false
        },
        column: {
            turboThreshold: 0
        }
    },
    tooltip : {
        crosshairs: [true, false],
        headerFormat: '<b>{series.name}</b><br>',
        pointFormat: '{point.timestamp}<br>y: <b>{point.y}</b>',
        valueDecimals: 2
    },
    series: data
});
}