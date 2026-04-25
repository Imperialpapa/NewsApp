import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/byok_settings.dart';
import 'byok_cache.dart';
import 'byok_summarizer.dart';

/// Holds BYOK-generated summaries for the current digest in memory and
/// orchestrates background re-generation. UI watches this and prefers
/// the BYOK summary over the server one whenever an entry exists.
class ByokSummaries extends ChangeNotifier {
  final ByokSummaryCache _cache;
  final Map<String, String> _byArticle = {};
  bool _running = false;
  String? _activeKey; // serialized settings used for current cache lookup

  ByokSummaries({ByokSummaryCache? cache})
      : _cache = cache ?? ByokSummaryCache();

  String? summaryFor(String articleId) => _byArticle[articleId];

  /// Re-hydrates the in-memory map from cache and kicks off live LLM
  /// generation for any article that doesn't yet have a cached entry.
  /// Safe to call repeatedly; concurrent calls coalesce.
  Future<void> refresh({
    required ByokSettings settings,
    required List<Article> articles,
  }) async {
    if (_running) return;
    if (!settings.isActive) {
      if (_byArticle.isNotEmpty) {
        _byArticle.clear();
        _activeKey = null;
        notifyListeners();
      }
      return;
    }
    final newKey = _settingsKey(settings);
    if (_activeKey != newKey) {
      _byArticle.clear();
      _activeKey = newKey;
      notifyListeners();
    }
    _running = true;
    try {
      // Hydrate cache hits first so cards swap quickly on cold launch.
      for (final a in articles) {
        if (_byArticle.containsKey(a.id)) continue;
        final cached = await _cache.get(a.id, settings);
        if (cached != null) {
          _byArticle[a.id] = cached;
        }
      }
      notifyListeners();

      // Live-generate the rest, sequential with a small spacing to keep
      // most free-tier user keys inside their RPM windows.
      final pending = articles.where((a) => !_byArticle.containsKey(a.id));
      final summarizer = ByokSummarizer(settings);
      try {
        for (final a in pending) {
          if (a.headline.isEmpty) continue;
          try {
            final result = await summarizer.summarize(
              headline: a.headline,
              snippet: a.snippet ?? '',
              source: a.sourceDisplayName,
            );
            _byArticle[a.id] = result;
            await _cache.set(a.id, settings, result);
            notifyListeners();
          } catch (e) {
            debugPrint('BYOK summarize failed for ${a.id}: $e');
            // Skip — server summary will be shown for this article.
          }
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      } finally {
        summarizer.close();
      }
    } finally {
      _running = false;
    }
  }

  static String _settingsKey(ByokSettings s) =>
      '${s.provider.id}|${s.modelOverride ?? ''}';
}
