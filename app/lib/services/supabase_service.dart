import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/digest.dart';
import '../models/user_prefs.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  Future<void> ensureSignedIn() async {
    if (_client.auth.currentUser == null) {
      await _client.auth.signInAnonymously();
    }
  }

  /// Latest digest (today's if available, else most recent).
  Future<Digest?> latestDigest() async {
    final rows = await _client
        .from('digests')
        .select('*, articles(*)')
        .order('digest_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Digest.fromJson(rows.first);
  }

  Future<UserPrefs> loadPrefs() async {
    final row = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId!)
        .single();
    return UserPrefs.fromJson(row);
  }

  Future<UserPrefs> savePrefs(UserPrefs prefs) async {
    final row = await _client
        .from('user_preferences')
        .update(prefs.toUpdatePayload())
        .eq('user_id', userId!)
        .select()
        .single();
    return UserPrefs.fromJson(row);
  }
}
