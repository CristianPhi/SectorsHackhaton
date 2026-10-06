import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the set of saved (favorited) Belajar item ids as reactive state.
///
/// Learning content — articles and videos — is saved by a stable id: an
/// article uses its `id`, a video uses its `youtubeId`. This mirrors the stock
/// favorites pattern: an in-memory set that every bookmark toggle and the
/// Favorit filter rebuild against. Kept in memory only (mock behavior): saves
/// survive tab and screen changes within a session but not a full restart.
///
/// A couple of items start saved so the Favorit view is not empty on first
/// open and the feature is discoverable.
class LearnFavoritesController extends Notifier<Set<String>> {
  static const Set<String> _seeded = <String>{'art-ihsg'};

  @override
  Set<String> build() => <String>{..._seeded};

  bool isSaved(String id) => state.contains(id);

  void toggle(String id) {
    final Set<String> next = <String>{...state};
    if (!next.remove(id)) {
      next.add(id);
    }
    state = next;
  }
}

/// The reactive set of saved Belajar item ids.
final NotifierProvider<LearnFavoritesController, Set<String>>
    learnFavoritesProvider =
    NotifierProvider<LearnFavoritesController, Set<String>>(
        LearnFavoritesController.new);
