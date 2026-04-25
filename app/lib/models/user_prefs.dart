class UserPrefs {
  final String userId;
  final String notifyTime; // "HH:MM:SS"
  final String language;   // 'ko' | 'en'
  final bool languageExplicit;
  final bool enabled;
  final List<String> enabledSources;
  final List<String> collapsedSources;

  const UserPrefs({
    required this.userId,
    required this.notifyTime,
    required this.language,
    required this.languageExplicit,
    required this.enabled,
    required this.enabledSources,
    required this.collapsedSources,
  });

  factory UserPrefs.fromJson(Map<String, dynamic> json) => UserPrefs(
        userId: json['user_id'] as String,
        notifyTime: json['notify_time'] as String,
        language: json['language'] as String,
        languageExplicit: json['language_explicit'] as bool? ?? false,
        enabled: json['enabled'] as bool,
        enabledSources:
            (json['enabled_sources'] as List<dynamic>).cast<String>(),
        collapsedSources:
            (json['collapsed_sources'] as List<dynamic>? ?? const [])
                .cast<String>(),
      );

  UserPrefs copyWith({
    String? notifyTime,
    String? language,
    bool? languageExplicit,
    bool? enabled,
    List<String>? enabledSources,
    List<String>? collapsedSources,
  }) =>
      UserPrefs(
        userId: userId,
        notifyTime: notifyTime ?? this.notifyTime,
        language: language ?? this.language,
        languageExplicit: languageExplicit ?? this.languageExplicit,
        enabled: enabled ?? this.enabled,
        enabledSources: enabledSources ?? this.enabledSources,
        collapsedSources: collapsedSources ?? this.collapsedSources,
      );

  Map<String, dynamic> toUpdatePayload() => {
        'notify_time': notifyTime,
        'language': language,
        'language_explicit': languageExplicit,
        'enabled': enabled,
        'enabled_sources': enabledSources,
        'collapsed_sources': collapsedSources,
      };

  /// Parse "HH:MM:SS" to hours + minutes.
  (int, int) get notifyHourMinute {
    final parts = notifyTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
