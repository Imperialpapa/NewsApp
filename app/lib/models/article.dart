class Article {
  final String id;
  final String source;
  final String headline;
  final String originalUrl;
  final DateTime? publishedAt;
  final String? summaryEn;
  final String? summaryKo;
  final String? snippet;
  final int rank;

  const Article({
    required this.id,
    required this.source,
    required this.headline,
    required this.originalUrl,
    required this.publishedAt,
    required this.summaryEn,
    required this.summaryKo,
    required this.snippet,
    required this.rank,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        source: json['source'] as String,
        headline: json['headline'] as String,
        originalUrl: json['original_url'] as String,
        publishedAt: json['published_at'] == null
            ? null
            : DateTime.parse(json['published_at'] as String),
        summaryEn: json['summary_en'] as String?,
        summaryKo: json['summary_ko'] as String?,
        snippet: json['snippet'] as String?,
        rank: json['rank'] as int,
      );

  bool get hasSummary =>
      (summaryEn != null && summaryEn!.isNotEmpty) ||
      (summaryKo != null && summaryKo!.isNotEmpty);

  bool get hasSnippet => snippet != null && snippet!.isNotEmpty;

  /// Returns summary in the requested language, or the other language as fallback.
  String? summaryIn(String language) {
    final primary = language == 'ko' ? summaryKo : summaryEn;
    if (primary != null && primary.isNotEmpty) return primary;
    final fallback = language == 'ko' ? summaryEn : summaryKo;
    return (fallback != null && fallback.isNotEmpty) ? fallback : null;
  }

  /// Display name per source key.
  String get sourceDisplayName => switch (source) {
        'bloomberg' => 'Bloomberg',
        'reuters' => 'Reuters',
        'ft' => 'Financial Times',
        'cnbc' => 'CNBC',
        'yahoo' => 'Yahoo Finance',
        'marketwatch' => 'MarketWatch',
        _ => source,
      };
}
