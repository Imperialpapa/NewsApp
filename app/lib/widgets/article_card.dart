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
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
