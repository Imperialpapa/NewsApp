import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../providers.dart';
import '../widgets/article_card.dart';

const _sourceDisplayNames = {
  'bloomberg': 'Bloomberg',
  'reuters': 'Reuters',
  'ft': 'Financial Times',
  'cnbc': 'CNBC',
  'marketwatch': 'MarketWatch',
  'yahoo': 'Yahoo Finance',
};

class DigestListScreen extends ConsumerWidget {
  const DigestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digestAsync = ref.watch(digestProvider);
    final prefsAsync = ref.watch(userPrefsProvider);
    final language =
        prefsAsync.maybeWhen(data: (p) => p.language, orElse: () => 'ko');
    final enabledSources =
        prefsAsync.maybeWhen(data: (p) => p.enabledSources, orElse: () => null);
    final isKo = language == 'ko';

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '오늘의 마켓' : 'Today\'s Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(digestProvider),
        child: digestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(error: e.toString(), isKo: isKo),
          data: (digest) {
            if (digest == null) {
              return _EmptyView(isKo: isKo);
            }
            final grouped =
                digest.groupedBySource(enabledSources: enabledSources);
            if (grouped.isEmpty) {
              return _EmptyView(isKo: isKo);
            }
            final dateStr = DateFormat(
              isKo ? 'yyyy년 M월 d일 (E)' : 'EEE, MMM d',
              isKo ? 'ko_KR' : 'en_US',
            ).format(digest.digestDate);
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    dateStr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
                for (final entry in grouped) ...[
                  _SourceHeader(
                    sourceKey: entry.key,
                    count: entry.value.length,
                  ),
                  for (final article in entry.value)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: ArticleCard(
                        article: article,
                        language: language,
                        onTap: () => _openArticle(article.originalUrl),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // silently swallow — phone may not have a browser
    }
  }
}

class _SourceHeader extends StatelessWidget {
  final String sourceKey;
  final int count;
  const _SourceHeader({required this.sourceKey, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            _sourceDisplayNames[sourceKey] ?? sourceKey,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· $count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const Expanded(child: SizedBox()),
          Container(
            height: 1,
            width: 40,
            color: theme.colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isKo;
  const _EmptyView({required this.isKo});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isKo
                  ? '아직 준비된 digest가 없습니다.\n매일 05:30 KST에 생성됩니다.'
                  : 'No digest yet.\nGenerated daily at 05:30 KST.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isKo;
  const _ErrorView({required this.error, required this.isKo});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '불러올 수 없습니다' : 'Could not load',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// Silence unused-import warning when Article isn't referenced directly.
// ignore: unused_element
void _keepArticleImport() => Article;
