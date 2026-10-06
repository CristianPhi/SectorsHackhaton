import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sectors_bob_app/features/favorites/favorites_controller.dart';

void main() {
  group('FavoritesController', () {
    test('starts with the seeded favorites BBCA and TLKM', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final Set<String> favorites = container.read(favoritesProvider);
      expect(favorites, containsAll(<String>{'BBCA', 'TLKM'}));
    });

    test('toggle removes a seeded favorite and adds a new one', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final FavoritesController notifier =
          container.read(favoritesProvider.notifier);

      // Adding a new favorite.
      expect(notifier.isFavorite('BBRI'), isFalse);
      notifier.toggle('BBRI');
      expect(container.read(favoritesProvider), contains('BBRI'));
      expect(notifier.isFavorite('BBRI'), isTrue);

      // Removing an existing (seeded) favorite.
      expect(notifier.isFavorite('BBCA'), isTrue);
      notifier.toggle('BBCA');
      expect(container.read(favoritesProvider), isNot(contains('BBCA')));
    });

    test('toggle is case-insensitive on the ticker', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final FavoritesController notifier =
          container.read(favoritesProvider.notifier);
      notifier.toggle('bbri');
      expect(container.read(favoritesProvider), contains('BBRI'));
    });
  });
}
