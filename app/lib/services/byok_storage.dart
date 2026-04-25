import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/byok_settings.dart';

/// Persists BYOK settings in platform secure storage (Android Keystore /
/// iOS Keychain). API keys never leave the device.
class ByokStorage {
  static const _kProvider = 'byok.provider';
  static const _kApiKey = 'byok.api_key';
  static const _kModel = 'byok.model_override';

  final FlutterSecureStorage _store;

  ByokStorage([FlutterSecureStorage? store])
      : _store = store ?? const FlutterSecureStorage();

  Future<ByokSettings> load() async {
    final providerId = await _store.read(key: _kProvider);
    final apiKey = await _store.read(key: _kApiKey) ?? '';
    final model = await _store.read(key: _kModel);
    return ByokSettings(
      provider: ByokProvider.fromId(providerId),
      apiKey: apiKey,
      modelOverride: (model == null || model.isEmpty) ? null : model,
    );
  }

  Future<void> save(ByokSettings s) async {
    await _store.write(key: _kProvider, value: s.provider.id);
    await _store.write(key: _kApiKey, value: s.apiKey);
    await _store.write(key: _kModel, value: s.modelOverride ?? '');
  }

  Future<void> clear() async {
    await _store.delete(key: _kProvider);
    await _store.delete(key: _kApiKey);
    await _store.delete(key: _kModel);
  }
}
