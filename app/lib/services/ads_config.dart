import 'package:flutter/foundation.dart';

/// AdMob ad-unit IDs for the app.
///
/// Debug builds always serve Google's official test ad unit (no real
/// requests, no revenue). Release builds use the real production unit.
/// This means `flutter run` is always safe to tap, and the only risk
/// surface is a release-mode APK installed on the dev's own phone —
/// in which case: do not tap your own ads (AdMob self-click ban).
class AdsConfig {
  // Google's standard Android banner test unit. See:
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  // Production banner unit for com.nolgaemi.todaysmarket.
  static const String _prodBannerAndroid =
      'ca-app-pub-3130573171479694/5153871905';

  static String get bannerAdUnitId =>
      kReleaseMode ? _prodBannerAndroid : _testBannerAndroid;
}
