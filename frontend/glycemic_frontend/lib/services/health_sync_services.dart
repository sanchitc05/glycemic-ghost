// lib/services/health_sync_service.dart
import 'dart:convert';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;

final _health = HealthFactory(useHealthConnectIfAvailable: true);

Future<void> syncHealthData(String token) async {
  final types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  final permissions = types.map((t) => HealthDataAccess.READ).toList();

  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));

  final granted =
      await _health.requestAuthorization(types, permissions: permissions);
  if (!granted) return;

  final data = await _health.getHealthDataFromTypes(yesterday, now, types);

  final metrics = data.map((d) {
    final type = d.type;
    String metricType;
    String unit;
    num value = d.value is num ? d.value as num : 0;

    switch (type) {
      case HealthDataType.STEPS:
        metricType = 'steps';
        unit = 'count';
        break;
      case HealthDataType.HEART_RATE:
        metricType = 'heart_rate';
        unit = 'bpm';
        break;
      case HealthDataType.BODY_MASS_INDEX:
        metricType = 'bmi';
        unit = 'kg/m2';
        break;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        metricType = 'active_energy';
        unit = 'kcal';
        break;
      default:
        metricType = type.toString();
        unit = '';
    }

    return {
      'metricType': metricType,
      'value': value,
      'unit': unit,
      'source': 'health_connect',
      'recordedAt': d.dateTo.toUtc().toIso8601String(),
      'extra': null,
    };
  }).toList();

  final res = await http.post(
    Uri.parse('http://localhost:4000/api/fitness/metrics/bulk'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'metrics': metrics}),
  );

  if (res.statusCode != 201) {
    // TODO: handle error (log, show snackbar, etc.)
  }
}
