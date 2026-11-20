import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: normalizeRole(map['role']),
    );
  }

  static String normalizeRole(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'admin' ? 'admin' : 'student';
  }
}

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data == null ? null : UserProfile.fromMap(data);
  }

  Future<UserProfile> updateName(String newName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Login diperlukan untuk memperbarui nama profil.');
    }

    final name = newName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(newName, 'newName', 'Nama tidak boleh kosong.');
    }

    final data = await _client
        .from('profiles')
        .update({'name': name})
        .eq('id', user.id)
        .select()
        .maybeSingle();

    if (data == null) {
      throw StateError('Profil tidak ditemukan atau tidak dapat diperbarui.');
    }

    return UserProfile.fromMap(data);
  }
}
