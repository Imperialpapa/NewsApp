class UserPrefs {
  final String userId;
  final String notifyTime; // "HH:MM:SS"
  final String language;   // 'ko' | 'en'
  final bool enabled;
  final List<String> enabledSources;

  const UserPrefs({
    required this.userId,
    required this.notifyTime,
    required this.language,
    required this.enabled,
    required this.enabledSources,
  });

  factory UserPrefs.fromJson(Map<String, dynamic> json) => UserPrefs(
        userId: json['user_id'] as String,
        notifyTime: json['notify_time'] as String,
        language: json['language'] as String,
        enabled: json['enabled'] as bool,
        enabledSources:
            (json['enabled_sources'] as List<dynamic>).cast<String>(),
      );

  UserPrefs copyWith({
    String? notifyTime,
    String? language,
    bool? enabled,
    List<String>? enabledSources,
  }) =>
      UserPrefs(
        userId: userId,
        notifyTime: notifyTime ?? this.notifyTime,
        language: language ?? this.language,
        enabled: enabled ?? this.enabled,
        enabledSources: enabledSources ?? this.enabledSources,
      );

  Map<String, dynamic> toUpdatePayload() => {
        'notify_time': notifyTime,
        'language': language,
        'enabled': enabled,
        'enabled_sources': enabledSources,
      };

  /// Parse "HH:MM:SS" to hours + minutes.
  (int, int) get notifyHourMinute {
    final parts = notifyTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
