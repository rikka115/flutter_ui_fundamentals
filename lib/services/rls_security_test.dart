import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RlsSecurityTest {
  RlsSecurityTest._();

  static const _deleteSentinelCode = 'RLS_TEST_DELETE_SENTINEL';

  static Future<void> runAsStudent() async {
    if (!kDebugMode) {
      throw StateError(
        'RLS security test hanya dapat dijalankan dalam mode debug.',
      );
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Login sebagai student sebelum menjalankan uji RLS.');
    }

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (profile?['role'] != 'student') {
      throw StateError(
        'Uji RLS hanya dapat dijalankan dengan akun role student.',
      );
    }

    await _testInsert(client, user.id);
    await _testUpdate(client);
    await _testDelete(client);
  }

  static Future<void> _testInsert(SupabaseClient client, String userId) async {
    try {
      final inserted = await client
          .from('courses')
          .insert({
            'code':
                'RLS_SECURITY_TEST_${userId}_${DateTime.now().microsecondsSinceEpoch}',
            'title': 'Temporary RLS security test',
            'credits': 1,
            'status': 'planned',
          })
          .select('id')
          .single();

      debugPrint('[FAIL] INSERT diizinkan oleh kebijakan RLS untuk student.');
      try {
        await client.from('courses').delete().eq('id', inserted['id']);
      } on Object catch (error) {
        debugPrint('[ERROR] Gagal membersihkan row test INSERT: $error');
      }
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        debugPrint('[PASS] INSERT ditolak oleh kebijakan RLS.');
      } else {
        debugPrint(
          '[FAIL] INSERT gagal dengan error selain penolakan RLS: $error',
        );
      }
    }
  }

  static Future<void> _testUpdate(SupabaseClient client) async {
    try {
      final course = await client
          .from('courses')
          .select('id, title')
          .order('id')
          .limit(1)
          .maybeSingle();
      if (course == null) {
        debugPrint('[SKIP] UPDATE tidak diuji karena tabel courses kosong.');
        return;
      }

      final updated = await client
          .from('courses')
          .update({'title': course['title']})
          .eq('id', course['id'])
          .select('id')
          .maybeSingle();
      if (updated == null) {
        debugPrint('[PASS] UPDATE ditolak oleh kebijakan RLS.');
      } else {
        debugPrint('[FAIL] UPDATE diizinkan oleh kebijakan RLS untuk student.');
      }
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        debugPrint('[PASS] UPDATE ditolak oleh kebijakan RLS.');
      } else {
        debugPrint(
          '[FAIL] UPDATE gagal dengan error selain penolakan RLS: $error',
        );
      }
    }
  }

  static Future<void> _testDelete(SupabaseClient client) async {
    try {
      final sentinel = await client
          .from('courses')
          .select('id')
          .eq('code', _deleteSentinelCode)
          .maybeSingle();
      if (sentinel == null) {
        debugPrint(
          '[SKIP] DELETE memerlukan row fixture disposable dengan code '
          '"$_deleteSentinelCode".',
        );
        return;
      }

      final deleted = await client
          .from('courses')
          .delete()
          .eq('id', sentinel['id'])
          .select('id')
          .maybeSingle();
      if (deleted == null) {
        debugPrint('[PASS] DELETE ditolak oleh kebijakan RLS.');
      } else {
        debugPrint(
          '[FAIL] DELETE diizinkan oleh RLS; hanya fixture disposable yang dihapus.',
        );
      }
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        debugPrint('[PASS] DELETE ditolak oleh kebijakan RLS.');
      } else {
        debugPrint(
          '[FAIL] DELETE gagal dengan error selain penolakan RLS: $error',
        );
      }
    }
  }
}
