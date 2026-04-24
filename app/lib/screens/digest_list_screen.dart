import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../models/sources.dart';
import '../models/user_prefs.dart';
import '../providers.dart';
import '../widgets/article_card.dart';

class DigestListScreen extends ConsumerStatefulWidget {
  const DigestListScreen({super.key});

  @override
  ConsumerState<DigestListScreen> createState() => _DigestListScreenState();
}

class _DigestListScreenState extends ConsumerState<DigestListScreen> {
  // Local optimistic copy. Seeded from prefs on first load so UI responds
  // instantly to taps; server save happens in the background.
  Set<String>? _collapsed;

  Future<void> _toggle(String sourceKey, UserPrefs currentPrefs) async {
    final current = _collapsed ?? currentPrefs.collapsedSources.toSet();
    final next = Set<String>.from(current);
    if (!next.remove(sourceKey)) next.add(sourceKey);
    setState(() => _collapsed = next);
    final updated = currentPrefs.copyWith(collapsedSources: next.toList());
    try {
      await ref.read(supabaseServiceProvider).savePrefs(updated);
      ref.invalidate(userPrefsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _collapsed = current); // revert on failure
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final digestAsync = ref.watch(digestProvider);
    final prefsAsync = ref.watch(userPrefsProvider);
    final language =
        prefsAsync.maybeWhen(data: (p) => p.language, orElse: () => 'ko');
    final enabledSources =
        prefsAsync.maybeWhen(data: (p) => p.enabledSources, orElse: () => null);
    final prefs = prefsAsync.asData?.value;
    // Seed local state from server once; after that, local state is the
    // source of truth so in-flight saves don't thrash the UI.
    _collapsed ??= prefs?.collapsedSources.toSet();
    final collapsedSet =
        _collapsed ?? prefs?.collapsedSources.toSet() ?? const <String>{};
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
                for (final entry in grouped)
                  _CollapsibleSourceSection(
                    sourceKey: entry.key,
                    articles: entry.value,
                    language: language,
                    collapsed: collapsedSet.contains(entry.key),
                    onToggle:
                        prefs == null ? null : () => _toggle(entry.key, prefs),
                    onOpenArticle: _openArticle,
                  ),
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

class _CollapsibleSourceSection extends StatelessWidget {
  final String sourceKey;
  final List<Article> articles;
  final String language;
  final bool collapsed;
  final VoidCallback? onToggle;
  final Future<void> Function(String url) onOpenArticle;

  const _CollapsibleSourceSection({
    required this.sourceKey,
    required this.articles,
    required this.language,
    required this.collapsed,
    required this.onToggle,
    required this.onOpenArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SourceHeader(
          sourceKey: sourceKey,
          count: articles.length,
          collapsed: collapsed,
          onTap: onToggle,
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      for (final article in articles)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: ArticleCard(
                            article: article,
                            language: language,
                            onTap: () => onOpenArticle(article.originalUrl),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SourceHeader extends StatelessWidget {
  final String sourceKey;
  final int count;
  final bool collapsed;
  final VoidCallback? onTap;

  const _SourceHeader({
    required this.sourceKey,
    required this.count,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: collapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              kSourceDisplayNames[sourceKey] ?? sourceKey,
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
