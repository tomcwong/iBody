class UserProfile {
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender;
  final String? avatarPath;

  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    this.avatarPath,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  double get heightFt => heightCm / 30.48;

  double get weightLbs => weightKg * 2.20462;

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? avatarPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'gender': gender,
    'avatarPath': avatarPath,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'User',
      age: map['age'] as int? ?? 30,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      gender: map['gender'] as String? ?? 'Other',
      avatarPath: map['avatarPath'] as String?,
    );
  }

  factory UserProfile.defaults() {
    return const UserProfile(
      name: 'User',
      age: 30,
      heightCm: 170.0,
      weightKg: 70.0,
      gender: 'Other',
    );
  }
}
