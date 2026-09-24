import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single comment on an article. Local-only in this mock (no backend).
class ArticleComment {
  const ArticleComment({
    required this.author,
    required this.text,
    required this.timeAgo,
    this.isMine = false,
  });

  final String author;
  final String text;
  final String timeAgo;

  /// True for comments the current user just posted, so the UI can mark them.
  final bool isMine;
}

/// Holds comments per article id as reactive, in-memory state.
///
/// Seeded with a couple of sample comments per article so the section looks
/// alive on first open. Posting appends locally and republishes; comments are
/// not persisted across a full restart, matching the app's other mocks.
class CommentsController extends Notifier<Map<String, List<ArticleComment>>> {
  @override
  Map<String, List<ArticleComment>> build() {
    return <String, List<ArticleComment>>{
      'art-ihsg': <ArticleComment>[
        const ArticleComment(
          author: 'Rina',
          text: 'Penjelasannya gampang dimengerti, makasih!',
          timeAgo: '2 jam lalu',
        ),
        const ArticleComment(
          author: 'Dimas',
          text: 'Menarik. Menurutku sektor perbankan masih kuat sih.',
          timeAgo: '1 jam lalu',
        ),
      ],
    };
  }

  /// Comments for [articleId], oldest first. Empty list when none.
  List<ArticleComment> forArticle(String articleId) =>
      state[articleId] ?? const <ArticleComment>[];

  /// Appends a new comment authored by the current user.
  void add(String articleId, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final List<ArticleComment> current =
        state[articleId] ?? const <ArticleComment>[];
    final ArticleComment comment = ArticleComment(
      author: 'Kamu',
      text: trimmed,
      timeAgo: 'Baru saja',
      isMine: true,
    );
    state = <String, List<ArticleComment>>{
      ...state,
      articleId: <ArticleComment>[...current, comment],
    };
  }
}

/// The reactive comments store, keyed by article id.
final NotifierProvider<CommentsController, Map<String, List<ArticleComment>>>
    commentsProvider =
    NotifierProvider<CommentsController, Map<String, List<ArticleComment>>>(
        CommentsController.new);
