/// Structured analysis models.
///
/// The chat AI returns a structured payload (not markdown) so the UI can render
/// clean, readable cards with progressive disclosure. A real backend can produce
/// the same JSON shape and drop in without touching the UI.

/// Direction of a data signal. This describes what the DATA says, it is never an
/// instruction to buy or sell.
enum Signal { bullish, netral, bearish }

/// Sentiment attached to a news headline.
enum Sentiment { positif, netral, negatif }

/// The exact, non-dismissable disclaimer required on every analysis.
const String kDyorDisclaimer =
    'Analisis ini bukan rekomendasi beli atau jual. Lakukan riset mandiri sebelum berinvestasi.';

Signal signalFromString(String? value) {
  switch (value) {
    case 'bullish':
      return Signal.bullish;
    case 'bearish':
      return Signal.bearish;
    default:
      return Signal.netral;
  }
}

String signalToString(Signal signal) => signal.name;

Sentiment sentimentFromString(String? value) {
  switch (value) {
    case 'positif':
      return Sentiment.positif;
    case 'negatif':
      return Sentiment.negatif;
    default:
      return Sentiment.netral;
  }
}

String sentimentToString(Sentiment sentiment) => sentiment.name;

/// A single technical indicator, for example RSI, MACD, or Moving Average.
class TechnicalIndicator {
  const TechnicalIndicator({
    required this.name,
    required this.value,
    required this.interpretation,
    required this.signal,
  });

  final String name;
  final String value;
  final String interpretation;
  final Signal signal;

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      name: json['name'] as String,
      value: json['value'] as String,
      interpretation: json['interpretation'] as String,
      signal: signalFromString(json['signal'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'interpretation': interpretation,
      'signal': signalToString(signal),
    };
  }
}

/// A single fundamental metric, for example P/E ratio or EPS growth.
class FundamentalMetric {
  const FundamentalMetric({
    required this.name,
    required this.value,
    required this.interpretation,
    required this.signal,
  });

  final String name;
  final String value;
  final String interpretation;
  final Signal signal;

  factory FundamentalMetric.fromJson(Map<String, dynamic> json) {
    return FundamentalMetric(
      name: json['name'] as String,
      value: json['value'] as String,
      interpretation: json['interpretation'] as String,
      signal: signalFromString(json['signal'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'interpretation': interpretation,
      'signal': signalToString(signal),
    };
  }
}

/// A news headline with a sentiment tag.
class NewsHeadline {
  const NewsHeadline({
    required this.title,
    required this.source,
    required this.sentiment,
  });

  final String title;
  final String source;
  final Sentiment sentiment;

  factory NewsHeadline.fromJson(Map<String, dynamic> json) {
    return NewsHeadline(
      title: json['title'] as String,
      source: json['source'] as String,
      sentiment: sentimentFromString(json['sentiment'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'source': source,
      'sentiment': sentimentToString(sentiment),
    };
  }
}

/// The full structured analysis returned by the chat AI.
class StockAnalysis {
  const StockAnalysis({
    required this.ticker,
    required this.title,
    required this.summary,
    required this.teknikal,
    required this.fundamental,
    required this.berita,
    this.disclaimer = kDyorDisclaimer,
  });

  final String ticker;
  final String title;

  /// Plain-language summary in Bahasa Indonesia, 2 to 3 sentences.
  final String summary;
  final List<TechnicalIndicator> teknikal;
  final List<FundamentalMetric> fundamental;
  final List<NewsHeadline> berita;
  final String disclaimer;

  factory StockAnalysis.fromJson(Map<String, dynamic> json) {
    return StockAnalysis(
      ticker: json['ticker'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String,
      teknikal: (json['teknikal'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => TechnicalIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      fundamental: (json['fundamental'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => FundamentalMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      berita: (json['berita'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => NewsHeadline.fromJson(e as Map<String, dynamic>))
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? kDyorDisclaimer,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticker': ticker,
      'title': title,
      'summary': summary,
      'teknikal': teknikal.map((e) => e.toJson()).toList(),
      'fundamental': fundamental.map((e) => e.toJson()).toList(),
      'berita': berita.map((e) => e.toJson()).toList(),
      'disclaimer': disclaimer,
    };
  }
}
