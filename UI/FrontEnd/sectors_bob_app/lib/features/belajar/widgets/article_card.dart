import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/bob_colors.dart';
import '../../../services/models/learn_models.dart';
import 'bookmark_button.dart';

/// A compact market-news row for the mixed Belajar feed: a small image on the
/// left, then source and time, the headline, and read time, matching the
/// recommendation rows in the reference. Tapping opens the in-app reader.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final LearnArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: context.c.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: context.c.surfaceLine),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: ColoredBox(
                    color: context.c.surfaceAlt,
                    child: Center(
                      child: Icon(
                        Icons.newspaper,
                        color: context.c.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          article.source,
                          style: text.bodySmall?.copyWith(
                            color: context.c.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.circle,
                            size: 3, color: context.c.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.timeAgo,
                            style: text.bodySmall?.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                        ),
                        // Save toggle, aligned to the row's right edge.
                        BookmarkButton(id: article.id),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: context.c.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: context.c.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.readTime,
                          style: text.bodySmall?.copyWith(
                            color: context.c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
