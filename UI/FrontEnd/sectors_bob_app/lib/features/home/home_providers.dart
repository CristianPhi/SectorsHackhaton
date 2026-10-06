import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/models/stock_models.dart';
import '../../services/providers.dart';
import '../favorites/favorites_controller.dart';

/// Local IDX stocks shown in the Discover list on Home.
final FutureProvider<List<Stock>> localStocksProvider =
    FutureProvider<List<Stock>>((ref) {
  return ref.watch(stockServiceProvider).localStocks();
});

/// The user's favorite stocks, shown in the Favorit list on Home.
///
/// Watches [favoritesProvider] so the list re-fetches whenever a favorite is
/// toggled anywhere in the app (a stock row heart, the stock detail heart).
final FutureProvider<List<Stock>> favoriteStocksProvider =
    FutureProvider<List<Stock>>((ref) {
  ref.watch(favoritesProvider);
  return ref.watch(stockServiceProvider).favorites();
});

/// Recently searched stocks shown in Riwayat Terakhir.
final FutureProvider<List<Stock>> recentlySearchedProvider =
    FutureProvider<List<Stock>>((ref) {
  return ref.watch(stockServiceProvider).recentlySearched();
});
