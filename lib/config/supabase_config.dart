/// Konfigurasi Supabase Client
/// Masukkan Project URL dan Anon Key dari dashboard Supabase Anda.
/// CATATAN KEAMANAN: Jangan pernah menaruh service_role key di aplikasi mobile!
class SupabaseConfig {
  static const String url = 'https://vvrkgvyvumhznbljitqw.supabase.co';
  static const String anonKey = 'sb_publishable_qJ0SeTbhO3X_ZL3OfClzbQ_oGzNqOM8';

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT_REF') &&
      !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}