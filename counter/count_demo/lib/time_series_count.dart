import 'package:json_annotation/json_annotation.dart';
part 'time_series_count.g.dart';

@JsonSerializable(createToJson: false)
class TimeSeriesCount {
  final int count;
  final DateTime date;

  TimeSeriesCount({required this.count, required this.date});

  factory TimeSeriesCount.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesCountFromJson(json);
}