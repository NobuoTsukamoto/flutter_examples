/// Example of a simple line chart.

import 'dart:convert';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'time_series_count.dart';
import 'package:intl/intl.dart';

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  const SimpleTimeSeriesChart(this.seriesList, {this.animate = false});

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory SimpleTimeSeriesChart.withData(List<TimeSeriesCount> data) {

    return SimpleTimeSeriesChart(
        _createSampleData(data),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Formatter for numeric ticks using [NumberFormat] to format into currency
    ///
    /// This is what is used in the [NumericAxisSpec] below.
    final simpleCurrencyFormatter =
    charts.BasicNumericTickFormatterSpec.fromNumberFormat(
        NumberFormat.compactSimpleCurrency());


    /// Formatter for numeric ticks that uses the callback provided.
    ///
    /// Use this formatter if you need to format values that [NumberFormat]
    /// cannot provide.
    ///
    /// To see this formatter, change [NumericAxisSpec] to use this formatter.
    // final customTickFormatter =
    //   charts.BasicNumericTickFormatterSpec((num value) => 'MyValue: $value');

    return charts.TimeSeriesChart(
        seriesList,
        animate: animate,
        primaryMeasureAxis: const NumericAxisSpec(
            tickProviderSpec: BasicNumericTickProviderSpec(
              zeroBound: true,
              dataIsInWholeNumbers: true,
              desiredTickCount: 6
            ),
            viewport: NumericExtents(0, 10),
            renderSpec: GridlineRendererSpec(
                lineStyle: charts.LineStyleSpec(
                    thickness: 1,
                ),
                labelStyle: TextStyleSpec(
                    fontSize: 18,
                )
            )
        ),
        domainAxis: const charts.DateTimeAxisSpec(
            tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
                minute: charts.TimeFormatterSpec(
                    format: 'm',
                    transitionFormat: 'MM/dd HH:mm'
                )
            ),
            renderSpec: SmallTickRendererSpec(
                labelStyle: TextStyleSpec(
                    fontSize: 18,
                )
            )
        )
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> _createSampleData(List<TimeSeriesCount> history) {
    List<TimeSeriesSales> data = [];

    for (var element in history) {
      data.add(TimeSeriesSales(element.date, element.count));
    }
    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Counts',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.count,
        data: data,
      )
    ];
  }
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime time;
  final int count;

  TimeSeriesSales(this.time, this.count);
}