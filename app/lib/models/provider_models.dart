import 'byok_settings.dart';

enum ModelTier { premium, balanced, economy }

class ModelOption {
  final String id;
  final String displayName;
  final ModelTier tier;

  const ModelOption({
    required this.id,
    required this.displayName,
    required this.tier,
  });

  factory ModelOption.fromJson(Map<String, dynamic> j) => ModelOption(
        id: j['id'] as String,
        displayName: j['name'] as String,
        tier: _tierFromString(j['tier'] as String?),
      );

  static ModelTier _tierFromString(String? s) => switch (s) {
        'premium' => ModelTier.premium,
        'economy' => ModelTier.economy,
        _ => ModelTier.balanced,
      };

  bool get isRecommended => tier == ModelTier.balanced;
}

/// Offline fallback used when the remote models.json fetch fails on a
/// cold install. Kept in sync with the contents of /models.json — if you
/// add a new tier or provider here, do the same in the JSON.
class BakedInModels {
  static const Map<ByokProvider, List<ModelOption>> byProvider = {
    ByokProvider.openai: [
      ModelOption(id: 'gpt-5', displayName: 'GPT-5', tier: ModelTier.premium),
      ModelOption(
          id: 'gpt-5-mini', displayName: 'GPT-5 mini', tier: ModelTier.balanced),
      ModelOption(
          id: 'gpt-4o-mini', displayName: 'GPT-4o mini', tier: ModelTier.economy),
    ],
    ByokProvider.gemini: [
      ModelOption(
          id: 'gemini-2.5-pro',
          displayName: 'Gemini 2.5 Pro',
          tier: ModelTier.premium),
      ModelOption(
          id: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          tier: ModelTier.balanced),
      ModelOption(
          id: 'gemini-2.5-flash-lite',
          displayName: 'Gemini 2.5 Flash Lite',
          tier: ModelTier.economy),
    ],
    ByokProvider.claude: [
      ModelOption(
          id: 'claude-opus-4-7',
          displayName: 'Claude Opus 4.7',
          tier: ModelTier.premium),
      ModelOption(
          id: 'claude-sonnet-4-6',
          displayName: 'Claude Sonnet 4.6',
          tier: ModelTier.balanced),
      ModelOption(
          id: 'claude-haiku-4-5',
          displayName: 'Claude Haiku 4.5',
          tier: ModelTier.economy),
    ],
  };
}
