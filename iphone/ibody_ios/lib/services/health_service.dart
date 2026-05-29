import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Bridges Apple HealthKit via the `health` Flutter package.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _authorized = false;

  static const _readTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  static const _writeTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
  ];

  Future<bool> requestPermissions() async {
    try {
      await Permission.activityRecognition.request();
      _authorized = await _health.requestAuthorization(
        _readTypes,
        permissions: _writeTypes.map((_) => HealthDataAccess.READ_WRITE).toList(),
      );
      return _authorized;
    } catch (e) {
      debugPrint('HealthKit permission error: $e');
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> getTodaySleepHours() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 16));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: yesterday,
        endTime: now,
      );
      double total = 0;
      for (final point in data) {
        if (point.value is NumericHealthValue) {
          total += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return total / 60.0; // minutes → hours
    } catch (e) {
      return 0;
    }
  }

  Future<bool> writeReading(HealthDataType type, double value) async {
    try {
      return await _health.writeHealthData(
        value: value,
        type: type,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('HealthKit write error: $e');
      return false;
    }
  }
}
