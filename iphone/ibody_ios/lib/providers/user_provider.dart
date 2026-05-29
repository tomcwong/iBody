import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class UserNotifier extends StateNotifier<UserProfile> {
  UserNotifier() : super(UserProfile.defaults()) {
    _load();
  }

  void _load() {
    state = StorageService.instance.loadProfile();
  }

  Future<void> update(UserProfile profile) async {
    await StorageService.instance.saveProfile(profile);
    state = profile;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>(
  (ref) => UserNotifier(),
);
