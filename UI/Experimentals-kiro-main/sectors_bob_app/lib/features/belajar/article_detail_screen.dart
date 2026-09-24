import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/learn_models.dart';
import 'belajar_screen.dart';
import 'comments_controller.dart';

/// In-app reader for a market news article, opened from the Belajar feed.
///
/// Mirrors the reference detail layout: an image header with a source badge, an
/// inert Comment / Like / Share action row (no backend), then the headline,
/// meta, and full body paragraphs. The article is looked up by id so navigation
/// can pass just the id.
class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LearnArticle>> articles =
        ref.watch(learnArticlesProvider);
    return TealBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.c.textOnCanvas,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disimpan ke bookmark.')),
              );
            },
            tooltip: 'Simpan',
            icon: const Icon(Icons.bookmark_border),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: articles.when(
        data: (List<LearnArticle> list) {
          final LearnArticle? article = _find(list);
          if (article == null) {
            return const _NotFound();
          }
          return _Body(article: article);
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.c.accent),
        ),
        error: (Object err, StackTrace stack) => const _NotFound(),
      ),
      ),
    );
  }

  LearnArticle? _find(List<LearnArticle> list) {
    for (final LearnArticle a in list) {
      if (a.id == articleId) {
        return a;
      }
    }
    return null;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.article});

  final LearnArticle article;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: <Widget>[
        _ImageHeader(source: article.source),
        const SizedBox(height: 12),
        const _ActionRow(),
        const SizedBox(height: 20),
        Text(
          article.title,
          style: text.headlineSmall?.copyWith(
            color: context.c.textOnCanvas,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Text(
              article.source,
              style: text.bodySmall?.copyWith(
                color: context.c.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 4, color: context.c.textOnCanvas2),
            const SizedBox(width: 8),
            Text(
              article.timeAgo,
              style: text.bodySmall?.copyWith(color: context.c.textOnCanvas2),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 4, color: context.c.textOnCanvas2),
            const SizedBox(width: 8),
            Text(
              article.readTime,
              style: text.bodySmall?.copyWith(color: context.c.textOnCanvas2),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final String paragraph in article.body) ...<Widget>[
          Text(
            paragraph,
            style: text.bodyLarge?.copyWith(
              color: context.c.textOnCanvas,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.c.bgElevated,
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(color: context.c.bgSunken),
          ),
          child: Text(
            'Berita ini bersifat informasi umum dan bukan rekomendasi beli '
            'atau jual. Lakukan riset mandiri sebelum berinvestasi.',
            style: text.bodySmall?.copyWith(color: context.c.textOnCanvas2),
          ),
        ),
        const SizedBox(height: 24),
        _CommentsSection(articleId: article.id),
      ],
    );
  }
}

/// The article comment section: a header with count, the list of comments, and
/// a composer to post a new one. Local-only (see [commentsProvider]).
class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.articleId});

  final String articleId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _post() {
    final String text = _input.text.trim();
    if (text.isEmpty) {
      return;
    }
    ref.read(commentsProvider.notifier).add(widget.articleId, text);
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<ArticleComment> comments = ref.watch(
      commentsProvider.select((m) =>
          m[widget.articleId] ?? const <ArticleComment>[]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.mode_comment_outlined,
                size: 18, color: context.c.textOnCanvas),
            const SizedBox(width: 8),
            Text(
              'Komentar',
              style: text.titleMedium?.copyWith(
                color: context.c.textOnCanvas,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${comments.length})',
              style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada komentar. Jadilah yang pertama berkomentar.',
              style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
            ),
          )
        else
          for (final ArticleComment c in comments) ...<Widget>[
            _CommentTile(comment: c),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        _CommentComposer(controller: _input, onSend: _post),
      ],
    );
  }
}

/// One comment: a small avatar with the author's initial, the name and time,
/// and the comment text.
class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ArticleComment comment;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String initial = comment.author.isNotEmpty
        ? comment.author.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.surfaceLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: comment.isMine ? context.c.accent : context.c.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(
                color: comment.isMine
                    ? context.c.textOnAccent
                    : context.c.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      comment.author,
                      style: text.bodyMedium?.copyWith(
                        color: context.c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: text.bodySmall
                          ?.copyWith(color: context.c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  style: text.bodyMedium?.copyWith(
                    color: context.c.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The composer: a rounded input with a gold circular send button.
class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.c.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              border: Border.all(color: context.c.surfaceLine),
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              style: TextStyle(color: context.c.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tulis komentar',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: context.c.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onSend,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.send_rounded,
                color: context.c.textOnAccent,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(
              color: context.c.bgElevated,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: context.c.textOnCanvas2,
                  size: 40,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0x66000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.newspaper,
                      size: 14,
                      color: context.c.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      source,
                      style: TextStyle(
                        color: context.c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Comment / Like / Share row. Comment and Like are live in this version;
/// Share is not built yet and shows a short "coming soon" note when tapped.
class _ActionRow extends StatefulWidget {
  const _ActionRow();

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _liked = false;

  void _shareNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur bagikan belum tersedia.')),
    );
  }

  void _scrollToComments() {
    // The comment section sits below in the same scroll view; nudge focus there
    // by scrolling to the end of the enclosing scrollable.
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    scrollable?.position.animateTo(
      scrollable.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.c.bgElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        border: Border.all(color: context.c.bgSunken),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _ActionItem(
            icon: Icons.mode_comment_outlined,
            label: 'Komentar',
            onTap: _scrollToComments,
          ),
          _ActionItem(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            label: 'Suka',
            active: _liked,
            onTap: () => setState(() => _liked = !_liked),
          ),
          _ActionItem(
            icon: Icons.share_outlined,
            label: 'Bagikan',
            onTap: _shareNote,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// When true the item is tinted with the gold accent (e.g. a liked state).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? context.c.accent : context.c.textOnCanvas;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Artikel tidak ditemukan.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: context.c.textOnCanvas2),
      ),
    );
  }
}
