import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? profile;
  bool isLoading = false;
  Object? error;

  String get role =>
      profile?.role ?? (SupabaseConfig.isConfigured ? 'student' : 'admin');
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
}
