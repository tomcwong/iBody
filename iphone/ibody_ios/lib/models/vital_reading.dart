enum VitalType {
  heartRate,
  spo2,
  temperature,
  respiratory,
  bloodPressureSys,
  bloodPressureDia,
  steps,
  sleep,
  stress,
  weight,
  bmi,
}

extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.heartRate: return 'Heart Rate';
      case VitalType.spo2: return 'Blood Oxygen';
      case VitalType.temperature: return 'Temperature';
      case VitalType.respiratory: return 'Respiratory Rate';
      case VitalType.bloodPressureSys: return 'Systolic BP';
      case VitalType.bloodPressureDia: return 'Diastolic BP';
      case VitalType.steps: return 'Steps';
      case VitalType.sleep: return 'Sleep';
      case VitalType.stress: return 'Stress Level';
      case VitalType.weight: return 'Weight';
      case VitalType.bmi: return 'BMI';
    }
  }

  String get unit {
    switch (this) {
      case VitalType.heartRate: return 'BPM';
      case VitalType.spo2: return '%';
      case VitalType.temperature: return '°F';
      case VitalType.respiratory: return 'br/min';
      case VitalType.bloodPressureSys:
      case VitalType.bloodPressureDia: return 'mmHg';
      case VitalType.steps: return 'steps';
      case VitalType.sleep: return 'hrs';
      case VitalType.stress: return '/100';
      case VitalType.weight: return 'lbs';
      case VitalType.bmi: return 'kg/m²';
    }
  }

  String get dbKey => name;
}

class VitalReading {
  final String id;
  final VitalType type;
  final double value;
  final DateTime timestamp;
  final String? notes;

  const VitalReading({
    required this.id,
    required this.type,
    required this.value,
    required this.timestamp,
    this.notes,
  });

  String get formattedValue {
    if (value == value.truncate()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  HealthStatus get status {
    switch (type) {
      case VitalType.heartRate:
        if (value < 60) return HealthStatus.low;
        if (value > 100) return HealthStatus.high;
        return HealthStatus.normal;
      case VitalType.spo2:
        if (value >= 95) return HealthStatus.normal;
        if (value >= 90) return HealthStatus.low;
        return HealthStatus.critical;
      case VitalType.temperature:
        if (value < 97.0) return HealthStatus.low;
        if (value > 99.5) return HealthStatus.high;
        return HealthStatus.normal;
      case VitalType.respiratory:
        if (value < 12) return HealthStatus.low;
        if (value > 20) return HealthStatus.high;
        return HealthStatus.normal;
      case VitalType.stress:
        if (value < 33) return HealthStatus.normal;
        if (value < 66) return HealthStatus.low;
        return HealthStatus.high;
      default:
        return HealthStatus.normal;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.dbKey,
    'value': value,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'notes': notes,
  };

  factory VitalReading.fromMap(Map<String, dynamic> map) {
    return VitalReading(
      id: map['id'] as String,
      type: VitalType.values.firstWhere((e) => e.dbKey == map['type']),
      value: (map['value'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }
}

enum HealthStatus { normal, low, high, critical }

extension HealthStatusExtension on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.normal: return 'Normal';
      case HealthStatus.low: return 'Low';
      case HealthStatus.high: return 'High';
      case HealthStatus.critical: return 'Critical';
    }
  }
}

// Double extension for truncation check
extension DoubleExt on double {
  double truncate() => toInt().toDouble();
}
