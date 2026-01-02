// lib/models/egv_record.dart

import 'package:flutter/cupertino.dart';

class EgvRecord {
  final DateTime systemTime;
  final DateTime displayTime;
  final int value;
  final int realtimeValue;
  final int smoothedValue;
  final String? status;
  final String? trend;
  final double? trendRate;

  final String? eventSource;  // 'CGM' or 'FOOD'
  final String? foodId;
  final String? foodName;

  EgvRecord({
    required this.systemTime,
    required this.displayTime,
    required this.value,
    required this.realtimeValue,
    required this.smoothedValue,
    this.status,
    this.trend,
    this.trendRate,
    this.eventSource,
    this.foodId,
    this.foodName,
  });

  factory EgvRecord.fromJson(Map<String, dynamic> json) {
    debugPrint('EGV JSON: $json');
    int intOrZero(dynamic v) => (v as int?) ?? 0;

    return EgvRecord(
      systemTime: DateTime.parse(json['systemTime'] as String),
      displayTime: DateTime.parse(json['displayTime'] as String),
      value: intOrZero(json['value']),
      realtimeValue: intOrZero(json['realtimeValue']),
      smoothedValue: intOrZero(json['smoothedValue']),
      status: json['status'] as String?,
      trend: json['trend'] as String?,
      trendRate: (json['trendRate'] as num?)?.toDouble(),
      eventSource: json['event_source'] as String?,
      foodId: json['food_id'] as String?,
      foodName: json['food_name'] as String?,
    );
  }
}
