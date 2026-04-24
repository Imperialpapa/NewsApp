import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/digest.dart';
import 'models/user_prefs.dart';
import 'services/supabase_service.dart';

final supabaseServiceProvider = Provider((_) => SupabaseService());

final digestProvider = FutureProvider<Digest?>((ref) async {
  final svc = ref.read(supabaseServiceProvider);
  await svc.ensureSignedIn();
  return svc.latestDigest();
});

final userPrefsProvider = FutureProvider<UserPrefs>((ref) async {
  final svc = ref.read(supabaseServiceProvider);
  await svc.ensureSignedIn();
  return svc.loadPrefs();
});
