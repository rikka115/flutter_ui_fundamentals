/// Konfigurasi Supabase Client
/// Masukkan Project URL dan Anon Key dari dashboard Supabase Anda.
/// CATATAN KEAMANAN: Jangan pernah menaruh service_role key di aplikasi mobile!
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT_REF') &&
      !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
