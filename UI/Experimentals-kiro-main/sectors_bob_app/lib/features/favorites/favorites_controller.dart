import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';

/// Holds the set of favorited tickers as reactive state.
///
/// The mock [StockService] owns the source of truth (seeded favorites persist,
/// session additions do not). This notifier mirrors that set so every heart
/// button and the Favorit list rebuild the moment a favorite is toggled,
/// without each widget having to poll the service. Toggling writes through to
/// the service and then republishes the updated set.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return ref.read(stockServiceProvider).favoriteTickers();
  }

  bool isFavorite(String ticker) => state.contains(ticker.toUpperCase());

  void toggle(String ticker) {
    final String upper = ticker.toUpperCase();
    final service = ref.read(stockServiceProvider);
    if (state.contains(upper)) {
      service.removeFavorite(upper);
    } else {
      service.addFavorite(upper);
    }
    // Republish a fresh copy from the service so state stays authoritative and
    // listeners see a new identity to rebuild against.
    state = service.favoriteTickers();
  }
}

/// The reactive set of favorited tickers.
final NotifierProvider<FavoritesController, Set<String>> favoritesProvider =
    NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);
