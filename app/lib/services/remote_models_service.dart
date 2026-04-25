import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/byok_settings.dart';
import '../models/provider_models.dart';

/// Loads the curated BYOK model list from a JSON file in the GitHub repo.
/// New models can be rolled out by editing /models.json on main — clients
/// pick it up within the cache TTL without an app update.
///
/// Resolution order:
///   1. Cached JSON if fetched within the TTL.
///   2. Network fetch (timeout-bounded). On success, cache + return.
///   3. Stale cached JSON (any age) if a fetch attempt failed.
///   4. Baked-in compile-time list as last resort.
class RemoteModelsService {
  static const _url =
      'https://raw.githubusercontent.com/Imperialpapa/NewsApp/main/models.json';
  static const _cacheKey = 'remote_models.body';
  static const _cacheTimestampKey = 'remote_models.fetched_at';
  static const _ttl = Duration(hours: 24);
  static const _fetchTimeout = Duration(seconds: 5);

  final http.Client _http;

  RemoteModelsService({http.Client? client}) : _http = client ?? http.Client();

  Future<Map<ByokProvider, List<ModelOption>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final fetchedAt = prefs.getInt(_cacheTimestampKey) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
    final isFresh = cached != null && age < _ttl.inMilliseconds;
    if (isFresh) {
      final parsed = _parse(cached);
      if (parsed != null) return parsed;
    }
    try {
      final resp =
          await _http.get(Uri.parse(_url)).timeout(_fetchTimeout);
      if (resp.statusCode == 200) {
        await prefs.setString(_cacheKey, resp.body);
        await prefs.setInt(
          _cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        final parsed = _parse(resp.body);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // network or timeout — fall through
    }
    if (cached != null) {
      final parsed = _parse(cached);
      if (parsed != null) return parsed;
    }
    return BakedInModels.byProvider;
  }

  Map<ByokProvider, List<ModelOption>>? _parse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final providers = data['providers'] as Map<String, dynamic>;
      final result = <ByokProvider, List<ModelOption>>{};
      for (final entry in providers.entries) {
        final p = ByokProvider.fromId(entry.key);
        if (p == ByokProvider.none) continue;
        result[p] = (entry.value as List)
            .map((m) => ModelOption.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      // Only treat as success if at least one provider parsed.
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}
