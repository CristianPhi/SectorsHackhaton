// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:stockwise/main.dart';

void main() {
  testWidgets('shows the Stockwise login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StockwiseApp());
    expect(find.text('Selamat datang\nkembali.'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  test('normalizes search rows with real prices', () {
    final row = {
      'symbol': 'BBCA',
      'name': 'PT Bank Central Asia Tbk.',
      'price': 6300,
      'change': -0.007874015748031496,
    };

    final normalized = normalizeSearchRow(row);

    expect(normalized['symbol'], 'BBCA');
    expect(normalized['price'], 6300.0);
    expect(normalized['change'], -0.007874015748031496);
  });
}
