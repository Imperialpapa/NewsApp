import 'package:flutter/material.dart';

import '../models/article.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final String language;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = article.summaryIn(language);
    final body = summary ?? (article.hasSnippet ? article.snippet : null);
    final isSnippetFallback = summary == null && article.hasSnippet;
    final headlineOnly = body == null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.sourceDisplayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${article.rank}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (headlineOnly) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.link,
                        size: 14, color: theme.colorScheme.outline),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(article.headline, style: theme.textTheme.titleMedium),
              if (body != null) ...[
                const SizedBox(height: 8),
                if (isSnippetFallback)
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  _BulletList(text: body, theme: theme),
                if (isSnippetFallback) ...[
                  const SizedBox(height: 4),
                  Text(
                    language == 'ko'
                        ? '— ${article.sourceDisplayName} 제공'
                        : '— via ${article.sourceDisplayName}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  language == 'ko' ? '원문 보기 →' : 'Read original →',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _BulletList({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bullets = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text('•', style: style),
              ),
              Expanded(child: Text(bullets[i], style: style)),
            ],
          ),
        ],
      ],
    );
  }
}
