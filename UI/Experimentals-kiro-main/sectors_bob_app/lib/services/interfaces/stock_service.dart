import '../models/stock_models.dart';

/// Stock data contract, covering lists and full detail with chart, technicals,
/// fundamentals, and news.
abstract class StockService {
  Future<List<Stock>> localStocks();

  Future<List<Stock>> favorites();

  Future<List<Stock>> recentlySearched();

  Future<StockDetail> detail(String ticker);

  /// The set of favorited tickers, read synchronously for toggle state. Seeded
  /// favorites are included.
  Set<String> favoriteTickers();

  /// Adds [ticker] to favorites. Seeded favorites persist across launches in a
  /// real backend; user-added favorites in this mock are kept in memory only.
  void addFavorite(String ticker);

  /// Removes [ticker] from favorites.
  void removeFavorite(String ticker);

  /// Filters all known stocks by ticker or name for the search screen. An empty
  /// query returns every stock.
  Future<List<Stock>> search(String query);
}
