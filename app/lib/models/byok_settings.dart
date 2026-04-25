/// User-supplied LLM API key configuration ("Bring Your Own Key").
///
/// Optional power-user feature on top of the server-generated digest:
/// when configured, the app re-summarizes articles client-side using
/// the user's own OpenAI / Gemini / Claude key for higher quality.
/// Default state (provider=none) keeps the centralized digest path.
enum ByokProvider {
  none('none', 'Off'),
  openai('openai', 'OpenAI'),
  gemini('gemini', 'Google Gemini'),
  claude('claude', 'Anthropic Claude');

  const ByokProvider(this.id, this.displayName);
  final String id;
  final String displayName;

  static ByokProvider fromId(String? id) =>
      values.firstWhere((p) => p.id == id, orElse: () => ByokProvider.none);
}

class ByokSettings {
  final ByokProvider provider;
  final String apiKey;
  final String? modelOverride;

  const ByokSettings({
    required this.provider,
    required this.apiKey,
    this.modelOverride,
  });

  static const ByokSettings off = ByokSettings(
    provider: ByokProvider.none,
    apiKey: '',
  );

  bool get isActive =>
      provider != ByokProvider.none && apiKey.trim().isNotEmpty;

  ByokSettings copyWith({
    ByokProvider? provider,
    String? apiKey,
    String? modelOverride,
  }) =>
      ByokSettings(
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        modelOverride: modelOverride ?? this.modelOverride,
      );
}
