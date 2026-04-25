import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/byok_settings.dart';
import 'models/digest.dart';
import 'models/user_prefs.dart';
import 'services/byok_storage.dart';
import 'services/byok_summary_notifier.dart';
import 'services/supabase_service.dart';

final supabaseServiceProvider = Provider((_) => SupabaseService());

final byokStorageProvider = Provider((_) => ByokStorage());

final byokSettingsProvider = FutureProvider<ByokSettings>(
  (ref) => ref.read(byokStorageProvider).load(),
);

final byokSummariesProvider =
    ChangeNotifierProvider<ByokSummaries>((_) => ByokSummaries());

final digestProvider = FutureProvider<Digest?>((ref) async {
  final svc = ref.read(supabaseServiceProvider);
  await svc.ensureSignedIn();
  return svc.latestDigest();
});

final userPrefsProvider = FutureProvider<UserPrefs>((ref) async {
  final svc = ref.read(supabaseServiceProvider);
  await svc.ensureSignedIn();
  final prefs = await svc.loadPrefs();
  if (prefs.languageExplicit) return prefs;
  // First launch (or pre-existing user pre-dating this feature): pick the
  // summary language from the device locale once, then mark as explicit so
  // future settings-screen choices stick.
  final deviceLanguage =
      PlatformDispatcher.instance.locale.languageCode == 'ko' ? 'ko' : 'en';
  return svc.savePrefs(
    prefs.copyWith(language: deviceLanguage, languageExplicit: true),
  );
});
