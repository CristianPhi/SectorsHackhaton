import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sectors_bob_app/features/chat/widgets/analysis_card.dart';
import 'package:sectors_bob_app/services/models/analysis_models.dart';

StockAnalysis _sampleAnalysis() {
  return const StockAnalysis(
    ticker: 'BBCA',
    title: 'Bank Central Asia (BBCA)',
    summary:
        'Bank Central Asia bergerak menguat pada perdagangan terakhir. '
        'Gambaran data cenderung positif. Ini ringkasan data, bukan ajakan '
        'mengambil posisi tertentu.',
    teknikal: <TechnicalIndicator>[
      TechnicalIndicator(
        name: 'RSI',
        value: '58,2',
        interpretation: 'Momentum netral cenderung menguat.',
        signal: Signal.netral,
      ),
      TechnicalIndicator(
        name: 'MACD',
        value: '+18,4',
        interpretation: 'Momentum positif.',
        signal: Signal.bullish,
      ),
    ],
    fundamental: <FundamentalMetric>[
      FundamentalMetric(
        name: 'P/E Ratio',
        value: '21,4x',
        interpretation: 'Sedikit di atas rata-rata sektor.',
        signal: Signal.netral,
      ),
    ],
    berita: <NewsHeadline>[
      NewsHeadline(
        title: 'Laba bersih di atas ekspektasi analis',
        source: 'Kontan',
        sentiment: Sentiment.positif,
      ),
    ],
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets('AnalysisCard renders the summary', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(AnalysisCard(analysis: _sampleAnalysis())));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bank Central Asia bergerak menguat'),
      findsOneWidget,
    );
  });

  testWidgets('AnalysisCard renders a TEKNIKAL row such as RSI',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(AnalysisCard(analysis: _sampleAnalysis())));
    await tester.pumpAndSettle();

    // The TEKNIKAL section is expanded by default, so RSI is visible.
    expect(find.text('TEKNIKAL'), findsOneWidget);
    expect(find.text('RSI'), findsOneWidget);
    expect(find.text('58,2'), findsOneWidget);
  });

  testWidgets('AnalysisCard shows the exact DYOR disclaimer',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(AnalysisCard(analysis: _sampleAnalysis())));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Analisis ini bukan rekomendasi beli atau jual. '
        'Lakukan riset mandiri sebelum berinvestasi.',
      ),
      findsOneWidget,
    );

    // The disclaimer is pinned and has no dismiss control.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}
