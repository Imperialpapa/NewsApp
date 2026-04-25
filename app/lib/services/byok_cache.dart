import 'package:shared_preferences/shared_preferences.dart';

import '../models/byok_settings.dart';

/// Persists BYOK-generated summaries keyed by (article_id, provider, model)
/// so changing the BYOK provider produces fresh summaries while a stable
/// configuration reuses cached results across launches.
class ByokSummaryCache {
  static const _prefix = 'byok_sum.';

  String _key(String articleId, ByokSettings s) {
    final model = s.modelOverride ?? '';
    return '$_prefix${s.provider.id}.$model.$articleId';
  }

  Future<String?> get(String articleId, ByokSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(articleId, s));
  }

  Future<void> set(
    String articleId,
    ByokSettings s,
    String summary,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(articleId, s), summary);
  }

  /// Drops every BYOK summary entry. Call when the user switches off BYOK
  /// or wants to force a re-generation.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
