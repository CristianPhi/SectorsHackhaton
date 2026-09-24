import '../interfaces/stock_service.dart';
import '../models/analysis_models.dart';
import '../models/stock_models.dart';

/// In-memory mock stock data for four IDX blue chips: BBCA, BBRI, BMRI, TLKM.
/// Values are realistic and formatted later with the id_ID locale in the UI.
class MockStockService implements StockService {
  MockStockService();

  static const Duration _latency = Duration(milliseconds: 600);

  static final Map<String, StockDetail> _details = _buildDetails();

  /// Favorites that a real backend would persist for the user. These always
  /// come back after a restart. Seeded per the product decision that BBCA and
  /// TLKM start favorited.
  static const Set<String> _seededFavorites = <String>{'BBCA', 'TLKM'};

  /// The live favorite set. Starts from the seeded favorites; toggles made in
  /// the running app mutate this in memory. Because [MockStockService] is
  /// constructed once by its provider and kept alive, toggles survive tab and
  /// screen changes within a session, but not a full app restart, which is the
  /// intended mock behavior: seeded favorites persist, user-added ones do not.
  final Set<String> _favorites = <String>{..._seededFavorites};

  List<Stock> get _all =>
      _details.values.map((detail) => detail.stock).toList(growable: false);

  @override
  Future<List<Stock>> localStocks() async {
    await Future<void>.delayed(_latency);
    return _all;
  }

  @override
  Future<List<Stock>> favorites() async {
    await Future<void>.delayed(_latency);
    return _all.where((Stock s) => _favorites.contains(s.ticker)).toList();
  }

  @override
  Future<List<Stock>> recentlySearched() async {
    await Future<void>.delayed(_latency);
    return <Stock>[
      _details['BBRI']!.stock,
      _details['BMRI']!.stock,
      _details['BBCA']!.stock,
    ];
  }

  @override
  Future<StockDetail> detail(String ticker) async {
    await Future<void>.delayed(_latency);
    final StockDetail? found = _details[ticker.toUpperCase()];
    if (found == null) {
      throw StateError('Saham $ticker tidak ditemukan pada data mock.');
    }
    return found;
  }

  @override
  Set<String> favoriteTickers() => Set<String>.unmodifiable(_favorites);

  @override
  void addFavorite(String ticker) => _favorites.add(ticker.toUpperCase());

  @override
  void removeFavorite(String ticker) => _favorites.remove(ticker.toUpperCase());

  @override
  Future<List<Stock>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _all;
    }
    return _all.where((Stock s) {
      return s.ticker.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q);
    }).toList();
  }

  /// Exposes the raw detail map so the chat mock can reuse the same data.
  static StockDetail? detailFor(String ticker) => _details[ticker.toUpperCase()];

  static Map<String, StockDetail> _buildDetails() {
    return <String, StockDetail>{
      'BBCA': StockDetail(
        stock: const Stock(
          ticker: 'BBCA',
          name: 'Bank Central Asia',
          sector: 'Perbankan',
          price: 10150,
          changePercent: 1.25,
          changeAbsolute: 125,
        ),
        description:
            'Bank swasta terbesar di Indonesia dengan basis nasabah ritel yang '
            'kuat dan rasio kredit bermasalah yang rendah.',
        marketCap: 1251000000000000,
        dayHigh: 10225,
        dayLow: 10025,
        sparkline: const <double>[
          9975, 10010, 9990, 10040, 10080, 10025, 10075, 10120, 10090, 10150,
        ],
        teknikal: const <TechnicalIndicator>[
          TechnicalIndicator(
            name: 'RSI',
            value: '58,2',
            interpretation:
                'Momentum masih netral cenderung menguat, belum masuk area jenuh beli.',
            signal: Signal.netral,
          ),
          TechnicalIndicator(
            name: 'MACD',
            value: '+18,4',
            interpretation:
                'Garis MACD berada di atas garis sinyal, mengindikasikan momentum positif.',
            signal: Signal.bullish,
          ),
          TechnicalIndicator(
            name: 'Moving Average',
            value: 'Di atas MA50',
            interpretation:
                'Harga bertahan di atas rata-rata 50 hari, tren jangka menengah cenderung naik.',
            signal: Signal.bullish,
          ),
        ],
        fundamental: const <FundamentalMetric>[
          FundamentalMetric(
            name: 'P/E Ratio',
            value: '21,4x',
            interpretation:
                'Sedikit di atas rata-rata sektor perbankan (sekitar 12,5x), mencerminkan premium kualitas.',
            signal: Signal.netral,
          ),
          FundamentalMetric(
            name: 'EPS Growth YoY',
            value: '+12,8%',
            interpretation:
                'Laba per saham tumbuh dua digit, ditopang pendapatan bunga bersih.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'Revenue Growth YoY',
            value: '+9,1%',
            interpretation:
                'Pertumbuhan pendapatan stabil seiring ekspansi kredit yang terjaga.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'Debt-to-Equity',
            value: '1,9x',
            interpretation:
                'Rasio wajar untuk sebuah bank, struktur permodalan tergolong sehat.',
            signal: Signal.netral,
          ),
        ],
        berita: const <NewsHeadline>[
          NewsHeadline(
            title: 'BBCA membukukan laba bersih kuartalan di atas ekspektasi analis',
            source: 'Kontan',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Rencana pembagian dividen interim menarik minat investor ritel',
            source: 'Bisnis Indonesia',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Suku bunga acuan yang tinggi menekan permintaan kredit baru',
            source: 'CNBC Indonesia',
            sentiment: Sentiment.netral,
          ),
        ],
      ),
      'BBRI': StockDetail(
        stock: const Stock(
          ticker: 'BBRI',
          name: 'Bank Rakyat Indonesia',
          sector: 'Perbankan',
          price: 4520,
          changePercent: -0.66,
          changeAbsolute: -30,
        ),
        description:
            'Bank dengan fokus pada segmen mikro dan UMKM, jaringan cabang '
            'terluas di seluruh Indonesia.',
        marketCap: 685000000000000,
        dayHigh: 4590,
        dayLow: 4500,
        sparkline: const <double>[
          4600, 4585, 4560, 4575, 4540, 4555, 4530, 4510, 4535, 4520,
        ],
        teknikal: const <TechnicalIndicator>[
          TechnicalIndicator(
            name: 'RSI',
            value: '43,7',
            interpretation:
                'Momentum melemah dan mendekati area netral bawah, tekanan jual mereda.',
            signal: Signal.netral,
          ),
          TechnicalIndicator(
            name: 'MACD',
            value: '-6,2',
            interpretation:
                'Garis MACD di bawah garis sinyal, momentum jangka pendek masih negatif.',
            signal: Signal.bearish,
          ),
          TechnicalIndicator(
            name: 'Moving Average',
            value: 'Di bawah MA20',
            interpretation:
                'Harga bergerak di bawah rata-rata 20 hari, tren pendek cenderung melemah.',
            signal: Signal.bearish,
          ),
        ],
        fundamental: const <FundamentalMetric>[
          FundamentalMetric(
            name: 'P/E Ratio',
            value: '11,2x',
            interpretation:
                'Di bawah rata-rata sektor (sekitar 12,5x), valuasi tergolong menarik.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'EPS Growth YoY',
            value: '+5,4%',
            interpretation:
                'Laba per saham tumbuh moderat, sedikit tertekan biaya pencadangan.',
            signal: Signal.netral,
          ),
          FundamentalMetric(
            name: 'Revenue Growth YoY',
            value: '+7,8%',
            interpretation:
                'Pendapatan tumbuh sehat ditopang kredit mikro yang berimbal hasil tinggi.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'Debt-to-Equity',
            value: '2,3x',
            interpretation:
                'Rasio sedikit lebih tinggi dari rekan sektornya, tetapi masih terkendali.',
            signal: Signal.netral,
          ),
        ],
        berita: const <NewsHeadline>[
          NewsHeadline(
            title: 'Kualitas kredit segmen mikro menunjukkan perbaikan bertahap',
            source: 'Kontan',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Biaya pencadangan naik menekan margin pada kuartal berjalan',
            source: 'Investor Daily',
            sentiment: Sentiment.negatif,
          ),
          NewsHeadline(
            title: 'Digitalisasi layanan mikro memperluas jangkauan nasabah baru',
            source: 'Bisnis Indonesia',
            sentiment: Sentiment.positif,
          ),
        ],
      ),
      'BMRI': StockDetail(
        stock: const Stock(
          ticker: 'BMRI',
          name: 'Bank Mandiri',
          sector: 'Perbankan',
          price: 6875,
          changePercent: 0.73,
          changeAbsolute: 50,
        ),
        description:
            'Salah satu bank BUMN terbesar dengan kekuatan pada segmen korporasi '
            'dan wholesale banking.',
        marketCap: 641000000000000,
        dayHigh: 6900,
        dayLow: 6800,
        sparkline: const <double>[
          6800, 6820, 6810, 6840, 6825, 6860, 6845, 6880, 6865, 6875,
        ],
        teknikal: const <TechnicalIndicator>[
          TechnicalIndicator(
            name: 'RSI',
            value: '55,9',
            interpretation:
                'Momentum netral cenderung positif, ruang penguatan masih terbuka.',
            signal: Signal.netral,
          ),
          TechnicalIndicator(
            name: 'MACD',
            value: '+9,7',
            interpretation:
                'Garis MACD baru memotong ke atas garis sinyal, sinyal momentum menguat.',
            signal: Signal.bullish,
          ),
          TechnicalIndicator(
            name: 'Moving Average',
            value: 'Di atas MA50',
            interpretation:
                'Harga bertahan di atas rata-rata 50 hari, tren menengah cenderung naik.',
            signal: Signal.bullish,
          ),
        ],
        fundamental: const <FundamentalMetric>[
          FundamentalMetric(
            name: 'P/E Ratio',
            value: '10,8x',
            interpretation:
                'Di bawah rata-rata sektor perbankan, valuasi relatif murah.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'EPS Growth YoY',
            value: '+14,2%',
            interpretation:
                'Pertumbuhan laba per saham kuat ditopang segmen wholesale.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'Revenue Growth YoY',
            value: '+10,3%',
            interpretation:
                'Pendapatan tumbuh dua digit dengan kontribusi kredit korporasi.',
            signal: Signal.bullish,
          ),
          FundamentalMetric(
            name: 'Debt-to-Equity',
            value: '2,1x',
            interpretation:
                'Struktur permodalan sehat dan sejalan dengan rerata bank BUMN.',
            signal: Signal.netral,
          ),
        ],
        berita: const <NewsHeadline>[
          NewsHeadline(
            title: 'Ekspansi kredit korporasi mendorong pertumbuhan aset produktif',
            source: 'Kontan',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Layanan digital wholesale mencatat volume transaksi rekor',
            source: 'CNBC Indonesia',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Fluktuasi nilai tukar rupiah menjadi perhatian manajemen risiko',
            source: 'Bisnis Indonesia',
            sentiment: Sentiment.netral,
          ),
        ],
      ),
      'TLKM': StockDetail(
        stock: const Stock(
          ticker: 'TLKM',
          name: 'Telkom Indonesia',
          sector: 'Telekomunikasi',
          price: 3210,
          changePercent: -1.23,
          changeAbsolute: -40,
        ),
        description:
            'Operator telekomunikasi terintegrasi terbesar dengan lini bisnis '
            'seluler, data center, dan infrastruktur digital.',
        marketCap: 318000000000000,
        dayHigh: 3280,
        dayLow: 3200,
        sparkline: const <double>[
          3290, 3270, 3260, 3275, 3250, 3240, 3255, 3230, 3225, 3210,
        ],
        teknikal: const <TechnicalIndicator>[
          TechnicalIndicator(
            name: 'RSI',
            value: '38,5',
            interpretation:
                'Momentum melemah dan mendekati area jenuh jual, tekanan mulai terbatas.',
            signal: Signal.bearish,
          ),
          TechnicalIndicator(
            name: 'MACD',
            value: '-11,3',
            interpretation:
                'Garis MACD di bawah garis sinyal, momentum jangka pendek negatif.',
            signal: Signal.bearish,
          ),
          TechnicalIndicator(
            name: 'Moving Average',
            value: 'Di bawah MA50',
            interpretation:
                'Harga berada di bawah rata-rata 50 hari, tren menengah cenderung menurun.',
            signal: Signal.bearish,
          ),
        ],
        fundamental: const <FundamentalMetric>[
          FundamentalMetric(
            name: 'P/E Ratio',
            value: '13,6x',
            interpretation:
                'Sejalan dengan rata-rata sektor telekomunikasi, valuasi tergolong wajar.',
            signal: Signal.netral,
          ),
          FundamentalMetric(
            name: 'EPS Growth YoY',
            value: '-3,2%',
            interpretation:
                'Laba per saham terkoreksi tipis akibat persaingan tarif data.',
            signal: Signal.bearish,
          ),
          FundamentalMetric(
            name: 'Revenue Growth YoY',
            value: '+4,5%',
            interpretation:
                'Pendapatan tumbuh moderat ditopang segmen data dan digital.',
            signal: Signal.netral,
          ),
          FundamentalMetric(
            name: 'Debt-to-Equity',
            value: '0,8x',
            interpretation:
                'Rasio utang rendah, memberikan ruang untuk belanja modal jaringan.',
            signal: Signal.bullish,
          ),
        ],
        berita: const <NewsHeadline>[
          NewsHeadline(
            title: 'Investasi data center diperkirakan menopang pertumbuhan jangka panjang',
            source: 'Investor Daily',
            sentiment: Sentiment.positif,
          ),
          NewsHeadline(
            title: 'Persaingan tarif data menekan margin segmen seluler',
            source: 'Kontan',
            sentiment: Sentiment.negatif,
          ),
          NewsHeadline(
            title: 'Kemitraan infrastruktur digital baru diumumkan manajemen',
            source: 'CNBC Indonesia',
            sentiment: Sentiment.positif,
          ),
        ],
      ),
    };
  }
}
