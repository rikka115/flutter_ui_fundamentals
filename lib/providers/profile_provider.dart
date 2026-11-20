import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? profile;
  bool isLoading = false;
  bool isUpdatingName = false;
  Object? error;

  String get role => profile?.role ?? 'student';
  bool get canManageCourses => role == 'admin';

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) return;

    isLoading = true;
    error = null;
    profile = null;
    notifyListeners();
    try {
      profile = await ProfileService().getMyProfile();
    } catch (e) {
      error = e;
      debugPrint('Gagal memuat profil: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateName(String newName) async {
    if (isUpdatingName) return;

    isUpdatingName = true;
    error = null;
    notifyListeners();
    try {
      profile = await ProfileService().updateName(newName);
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      isUpdatingName = false;
      notifyListeners();
    }
  }
}
