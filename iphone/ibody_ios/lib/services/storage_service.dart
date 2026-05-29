import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vital_reading.dart';
import '../models/user_profile.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Database _db;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'ibody.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vital_readings (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            value REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            notes TEXT
          )
        ''');
      },
    );
  }

  // Vital Readings
  Future<void> saveReading(VitalReading reading) async {
    await _db.insert(
      'vital_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VitalReading>> getReadings(VitalType type, {int limit = 50}) async {
    final maps = await _db.query(
      'vital_readings',
      where: 'type = ?',
      whereArgs: [type.dbKey],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  Future<VitalReading?> getLatestReading(VitalType type) async {
    final maps = await _db.query(
      'vital_readings',
      where: 'type = ?',
      whereArgs: [type.dbKey],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VitalReading.fromMap(maps.first);
  }

  Future<List<VitalReading>> getTodaysReadings() async {
    final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0).millisecondsSinceEpoch;
    final maps = await _db.query(
      'vital_readings',
      where: 'timestamp >= ?',
      whereArgs: [start],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  Future<void> deleteReading(String id) async {
    await _db.delete('vital_readings', where: 'id = ?', whereArgs: [id]);
  }

  // User Profile
  Future<void> saveProfile(UserProfile profile) async {
    final map = profile.toMap();
    map.forEach((key, value) {
      if (value != null) _prefs.setString('profile_$key', value.toString());
    });
  }

  UserProfile loadProfile() {
    final map = <String, dynamic>{
      'name': _prefs.getString('profile_name'),
      'age': int.tryParse(_prefs.getString('profile_age') ?? ''),
      'heightCm': double.tryParse(_prefs.getString('profile_heightCm') ?? ''),
      'weightKg': double.tryParse(_prefs.getString('profile_weightKg') ?? ''),
      'gender': _prefs.getString('profile_gender'),
      'avatarPath': _prefs.getString('profile_avatarPath'),
    };
    return UserProfile.fromMap(map);
  }

  // Onboarding flag
  bool get onboardingComplete => _prefs.getBool('onboarding_done') ?? false;
  Future<void> markOnboardingComplete() => _prefs.setBool('onboarding_done', true);
}

extension DateTimeCopyWith on DateTime {
  DateTime copyWith({int? hour, int? minute, int? second}) => DateTime(
    year,
    month,
    day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
  );
}
