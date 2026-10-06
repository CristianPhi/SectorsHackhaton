import 'package:flutter_test/flutter_test.dart';
import 'package:sectors_bob_app/services/models/analysis_models.dart';
import 'package:sectors_bob_app/services/models/stock_models.dart';
import 'package:sectors_bob_app/services/mock/mock_chat_service.dart';

void main() {
  test('sendMessage emits a thinking message before the final analysis',
      () async {
    final MockChatService service = MockChatService();

    final List<ChatMessage> received = await service
        .sendMessage('Bagaimana BBCA hari ini?', ticker: 'BBCA')
        .toList();

    // Two phases: the thinking placeholder, then the final analysis.
    expect(received.length, 2);

    final ChatMessage first = received.first;
    expect(first.isThinking, isTrue);
    expect(first.analysis, isNull);

    final ChatMessage last = received.last;
    expect(last.isThinking, isFalse);
    expect(last.analysis, isNotNull);
  });

  test('final analysis contains the exact DYOR disclaimer', () async {
    final MockChatService service = MockChatService();

    final List<ChatMessage> received =
        await service.sendMessage('analisis TLKM', ticker: 'TLKM').toList();

    final StockAnalysis analysis = received.last.analysis!;
    expect(
      analysis.disclaimer,
      'Analisis ini bukan rekomendasi beli atau jual. '
      'Lakukan riset mandiri sebelum berinvestasi.',
    );
    expect(analysis.disclaimer, kDyorDisclaimer);
    expect(analysis.teknikal, isNotEmpty);
  });
}
