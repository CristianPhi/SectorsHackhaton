import '../interfaces/chat_service.dart';
import '../models/analysis_models.dart';
import '../models/stock_models.dart';
import 'mock_stock_service.dart';

/// Mock chat that simulates a progressive thinking state, then returns a
/// structured analysis in Bahasa Indonesia. It reuses MockStockService data so
/// the numbers stay consistent with the stock detail screen.
class MockChatService implements ChatService {
  MockChatService();

  static const Duration _thinkTime = Duration(milliseconds: 1600);

  int _counter = 0;

  String _nextId() => 'msg-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  /// Resolves a ticker from an explicit hint or by scanning the prompt text.
  /// Falls back to BBCA so the demo always has data to show.
  String _resolveTicker(String prompt, String? ticker) {
    if (ticker != null && ticker.trim().isNotEmpty) {
      final String candidate = ticker.trim().toUpperCase();
      if (MockStockService.detailFor(candidate) != null) {
        return candidate;
      }
    }
    final String upper = prompt.toUpperCase();
    for (final String known in <String>['BBCA', 'BBRI', 'BMRI', 'TLKM']) {
      if (upper.contains(known)) {
        return known;
      }
    }
    final String lower = prompt.toLowerCase();
    const Map<String, String> byName = <String, String>{
      'bca': 'BBCA',
      'central asia': 'BBCA',
      'bri': 'BBRI',
      'rakyat': 'BBRI',
      'mandiri': 'BMRI',
      'telkom': 'TLKM',
    };
    for (final MapEntry<String, String> entry in byName.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'BBCA';
  }

  @override
  Stream<ChatMessage> sendMessage(String prompt, {String? ticker}) async* {
    yield ChatMessage.thinking(id: _nextId());
    await Future<void>.delayed(_thinkTime);

    final String resolved = _resolveTicker(prompt, ticker);
    final StockDetail detail = MockStockService.detailFor(resolved)!;

    final StockAnalysis analysis = StockAnalysis(
      ticker: detail.ticker,
      title: '${detail.name} (${detail.ticker})',
      summary: _summaryFor(detail),
      teknikal: detail.teknikal,
      fundamental: detail.fundamental,
      berita: detail.berita,
    );

    yield ChatMessage.analysis(id: _nextId(), analysis: analysis);
  }

  String _summaryFor(StockDetail detail) {
    final String arah = detail.stock.isUp ? 'menguat' : 'melemah';
    final int bullishCount =
        detail.teknikal.where((t) => t.signal == Signal.bullish).length +
            detail.fundamental.where((f) => f.signal == Signal.bullish).length;
    final int bearishCount =
        detail.teknikal.where((t) => t.signal == Signal.bearish).length +
            detail.fundamental.where((f) => f.signal == Signal.bearish).length;

    final String kondisi;
    if (bullishCount > bearishCount) {
      kondisi = 'Secara keseluruhan gambaran data cenderung positif, dengan '
          'sinyal teknikal dan fundamental yang lebih banyak menguat.';
    } else if (bearishCount > bullishCount) {
      kondisi = 'Secara keseluruhan gambaran data cenderung tertekan, dengan '
          'beberapa sinyal teknikal dan fundamental yang melemah.';
    } else {
      kondisi = 'Gambaran data saat ini cenderung berimbang antara sinyal yang '
          'menguat dan yang melemah.';
    }

    return '${detail.name} bergerak $arah pada perdagangan terakhir di sektor '
        '${detail.stock.sector.toLowerCase()}. $kondisi Perhatikan bahwa ini adalah '
        'ringkasan data, bukan ajakan untuk mengambil posisi tertentu.';
  }
}
