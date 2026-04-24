/// Single source of truth for the app's news sources.
///
/// Adding a new source requires updates in three places:
///   1. This file (display order + name)
///   2. `backend/sources.py` (RSS fetch config)
///   3. A new Supabase migration updating
///      `user_preferences.enabled_sources` default + backfill
library;

const kAllSources = [
  'bloomberg',
  'reuters',
  'ft',
  'cnbc',
  'marketwatch',
  'yahoo',
  'nikkei_asia',
];

const kSourceDisplayNames = {
  'bloomberg': 'Bloomberg',
  'reuters': 'Reuters',
  'ft': 'Financial Times',
  'cnbc': 'CNBC',
  'marketwatch': 'MarketWatch',
  'yahoo': 'Yahoo Finance',
  'nikkei_asia': 'Nikkei Asia',
};
