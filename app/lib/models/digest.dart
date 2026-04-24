import 'article.dart';

/// Display order for source sections — reputation/relevance weighted.
const kSourceDisplayOrder = [
  'bloomberg',
  'reuters',
  'ft',
  'cnbc',
  'marketwatch',
  'yahoo',
];

class Digest {
  final String id;
  final DateTime digestDate;
  final DateTime generatedAt;
  final String provider;
  final int articleCount;
  final List<Article> articles;

  const Digest({
    required this.id,
    required this.digestDate,
    required this.generatedAt,
    required this.provider,
    required this.articleCount,
    required this.articles,
  });

  factory Digest.fromJson(Map<String, dynamic> json) {
    final articles = (json['articles'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Digest(
      id: json['id'] as String,
      digestDate: DateTime.parse(json['digest_date'] as String),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      provider: json['provider'] as String,
      articleCount: json['article_count'] as int,
      articles: articles,
    );
  }

  /// Groups articles by source, filtered by `enabledSources` if provided,
  /// ordered per `kSourceDisplayOrder`. Articles within each source are
  /// ordered by rank ascending (1 = most prominent).
  List<MapEntry<String, List<Article>>> groupedBySource({
    List<String>? enabledSources,
  }) {
    final map = <String, List<Article>>{};
    for (final a in articles) {
      if (enabledSources != null && !enabledSources.contains(a.source)) {
        continue;
      }
      map.putIfAbsent(a.source, () => []).add(a);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.rank.compareTo(b.rank));
    }
    return [
      for (final key in kSourceDisplayOrder)
        if (map[key] != null && map[key]!.isNotEmpty)
          MapEntry(key, map[key]!),
    ];
  }
}
