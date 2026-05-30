import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../models/vital_reading.dart';
import '../services/health_service.dart';
import '../services/storage_service.dart';

class HealthState {
  final Map<VitalType, VitalReading?> latestReadings;
  final Map<VitalType, List<VitalReading>> history;
  final List<VitalReading> todaysReadings;
  final bool isLoading;

  const HealthState({
    this.latestReadings = const {},
    this.history = const {},
    this.todaysReadings = const [],
    this.isLoading = false,
  });

  HealthState copyWith({
    Map<VitalType, VitalReading?>? latestReadings,
    Map<VitalType, List<VitalReading>>? history,
    List<VitalReading>? todaysReadings,
    bool? isLoading,
  }) {
    return HealthState(
      latestReadings: latestReadings ?? this.latestReadings,
      history: history ?? this.history,
      todaysReadings: todaysReadings ?? this.todaysReadings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 0-100 health score based on latest vital readings
  int get healthScore {
    int score = 100;

    final hr = latestReadings[VitalType.heartRate];
    if (hr != null) {
      if (hr.status == HealthStatus.low || hr.status == HealthStatus.high) score -= 10;
      else if (hr.status == HealthStatus.critical) score -= 20;
    }

    final spo2 = latestReadings[VitalType.spo2];
    if (spo2 != null) {
      if (spo2.status == HealthStatus.low) score -= 15;
      else if (spo2.status == HealthStatus.critical) score -= 30;
    }

    final temp = latestReadings[VitalType.temperature];
    if (temp != null) {
      if (temp.status != HealthStatus.normal) score -= 10;
    }

    return score.clamp(0, 100);
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(const HealthState()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true);
    final storage = StorageService.instance;

    final latest = <VitalType, VitalReading?>{};
    final history = <VitalType, List<VitalReading>>{};

    for (final type in VitalType.values) {
      latest[type] = await storage.getLatestReading(type);
      history[type] = await storage.getReadings(type, limit: 30);
    }

    final todays = await storage.getTodaysReadings();

    state = state.copyWith(
      latestReadings: latest,
      history: history,
      todaysReadings: todays,
      isLoading: false,
    );
  }

  Future<void> saveReading(VitalReading reading) async {
    await StorageService.instance.saveReading(reading);
    _syncToHealthKit(reading);
    await _loadAll();
  }

  void _syncToHealthKit(VitalReading reading) {
    final HealthDataType? hkType = switch (reading.type) {
      VitalType.heartRate => HealthDataType.HEART_RATE,
      VitalType.spo2 => HealthDataType.BLOOD_OXYGEN,
      VitalType.temperature => HealthDataType.BODY_TEMPERATURE,
      VitalType.weight => HealthDataType.WEIGHT,
      _ => null,
    };
    if (hkType != null) {
      HealthService.instance.writeReading(hkType, reading.value);
    }
  }

  Future<void> refresh() => _loadAll();
}

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>(
  (ref) => HealthNotifier(),
);
