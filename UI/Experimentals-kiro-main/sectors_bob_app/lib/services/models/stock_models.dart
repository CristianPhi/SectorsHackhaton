import 'analysis_models.dart';

/// A stock summary used in lists (local stocks, favorites, recent).
class Stock {
  const Stock({
    required this.ticker,
    required this.name,
    required this.sector,
    required this.price,
    required this.changePercent,
    required this.changeAbsolute,
  });

  final String ticker;
  final String name;
  final String sector;

  /// Last price in IDR.
  final double price;

  /// Daily change in percent, positive for up, negative for down.
  final double changePercent;

  /// Daily change in absolute IDR, positive for up, negative for down.
  final double changeAbsolute;

  bool get isUp => changePercent >= 0;

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      changeAbsolute: (json['changeAbsolute'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticker': ticker,
      'name': name,
      'sector': sector,
      'price': price,
      'changePercent': changePercent,
      'changeAbsolute': changeAbsolute,
    };
  }
}

/// A full stock detail including chart points and the structured breakdowns.
class StockDetail {
  const StockDetail({
    required this.stock,
    required this.description,
    required this.marketCap,
    required this.dayHigh,
    required this.dayLow,
    required this.sparkline,
    required this.teknikal,
    required this.fundamental,
    required this.berita,
  });

  final Stock stock;
  final String description;

  /// Market capitalisation in IDR.
  final double marketCap;
  final double dayHigh;
  final double dayLow;

  /// Chart points for the mini price chart.
  final List<double> sparkline;
  final List<TechnicalIndicator> teknikal;
  final List<FundamentalMetric> fundamental;
  final List<NewsHeadline> berita;

  String get ticker => stock.ticker;
  String get name => stock.name;

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    return StockDetail(
      stock: Stock.fromJson(json['stock'] as Map<String, dynamic>),
      description: json['description'] as String,
      marketCap: (json['marketCap'] as num).toDouble(),
      dayHigh: (json['dayHigh'] as num).toDouble(),
      dayLow: (json['dayLow'] as num).toDouble(),
      sparkline: (json['sparkline'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      teknikal: (json['teknikal'] as List<dynamic>)
          .map((e) => TechnicalIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      fundamental: (json['fundamental'] as List<dynamic>)
          .map((e) => FundamentalMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      berita: (json['berita'] as List<dynamic>)
          .map((e) => NewsHeadline.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stock': stock.toJson(),
      'description': description,
      'marketCap': marketCap,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'sparkline': sparkline,
      'teknikal': teknikal.map((e) => e.toJson()).toList(),
      'fundamental': fundamental.map((e) => e.toJson()).toList(),
      'berita': berita.map((e) => e.toJson()).toList(),
    };
  }
}

/// Role of a chat message.
enum ChatRole { user, assistant }

/// A single chat message. User messages carry [text]. Assistant messages carry
/// a structured [analysis], or [isThinking] while the response is being formed.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.analysis,
    this.isThinking = false,
  });

  final String id;
  final ChatRole role;
  final String? text;
  final StockAnalysis? analysis;
  final bool isThinking;

  factory ChatMessage.user({required String id, required String text}) {
    return ChatMessage(id: id, role: ChatRole.user, text: text);
  }

  factory ChatMessage.thinking({required String id}) {
    return ChatMessage(id: id, role: ChatRole.assistant, isThinking: true);
  }

  factory ChatMessage.analysis({
    required String id,
    required StockAnalysis analysis,
  }) {
    return ChatMessage(id: id, role: ChatRole.assistant, analysis: analysis);
  }

  bool get isUser => role == ChatRole.user;
}
