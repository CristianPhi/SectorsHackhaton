import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFFF2F5F3);
const _muted = Color(0xFF8A9690);
const _mint = Color(0xFF1E402F);
const _green = Color(0xFF55D887);
const _coral = Color(0xFFE8775D);
const _cream = Color(0xFF121212);
const _surface = Color(0xFF1B1B1B);
const _surfaceRaised = Color(0xFF242424);
const _aiPanel = Color(0xFF103A2A);
const _agentBaseUrl = kIsWeb ? 'http://localhost:3002' : 'http://10.0.2.2:3002';
const _newsBaseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class MarketStock {
  const MarketStock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
  });
  final String symbol;
  final String name;
  final double? price;
  final double? change;

  factory MarketStock.fromJson(Map<String, dynamic> json) => MarketStock(
    symbol: json['symbol']?.toString() ?? '-',
    name: json['name']?.toString() ?? '-',
    price: (json['price'] as num?)?.toDouble(),
    change: (json['change'] as num?)?.toDouble(),
  );
}

class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore instance = WatchlistStore._();
  WatchlistStore._();
  final Map<String, MarketStock> _stocks = {};

  List<MarketStock> get stocks => _stocks.values.toList();
  bool contains(String symbol) => _stocks.containsKey(symbol);

  void toggle(MarketStock stock) {
    if (contains(stock.symbol)) {
      _stocks.remove(stock.symbol);
    } else {
      _stocks[stock.symbol] = stock;
    }
    notifyListeners();
  }
}

class MarketApi {
  static Future<Map<String, dynamic>> getSnapshot() async {
    final response = await http.get(Uri.parse('$_agentBaseUrl/sectors/market'));
    if (response.statusCode >= 400) {
      throw Exception('Gagal mengambil data market');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> search(String query) async {
    final uri = Uri.parse('$_agentBaseUrl/sectors/search').replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
    );
    final response = await http.get(uri);
    if (response.statusCode >= 400)
      throw Exception('Gagal mengambil data pencarian');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStockDetail(String symbol) async {
    final response = await http.get(
      Uri.parse('$_agentBaseUrl/sectors/stocks/$symbol'),
    );
    if (response.statusCode >= 400)
      throw Exception('Gagal mengambil detail saham');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStockQuote(String symbol) async {
    final response = await http.get(
      Uri.parse('$_agentBaseUrl/sectors/stocks/$symbol/quote'),
    );
    if (response.statusCode >= 400)
      throw Exception('Gagal mengambil quote saham');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getBrokerSummary(String symbol) async {
    final response = await http.get(
      Uri.parse('$_agentBaseUrl/broker/summary/$symbol'),
    );
    if (response.statusCode >= 400)
      throw Exception('Gagal mengambil broker summary');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, String>> getBrokerNames() async {
    final response = await http.get(Uri.parse('$_agentBaseUrl/broker/brokers'));
    if (response.statusCode >= 400) return {};
    final rows = jsonDecode(response.body) as List<dynamic>? ?? const [];
    final map = <String, String>{};
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        final code = (row['code'] ?? '').toString();
        final name = (row['name'] ?? code).toString();
        if (code.isNotEmpty) map[code] = name;
      }
    }
    return map;
  }

  static Future<List<NewsItem>> getNews() async {
    final response = await http.get(Uri.parse('$_newsBaseUrl/api/news'));
    if (response.statusCode >= 400) throw Exception('Gagal mengambil berita');
    final decoded = jsonDecode(response.body);
    final rows = decoded is List
        ? decoded
        : (decoded is Map
              ? (decoded['results'] ?? decoded['data'] ?? decoded['news'] ?? [])
              : []);
    return (rows as List)
        .whereType<Map>()
        .map((row) => NewsItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.sector,
    required this.time,
    required this.url,
    required this.source,
  });
  final String title;
  final String sector;
  final String time;
  final String url;
  final String source;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final sector =
        json['sector'] ?? json['sub_sector'] ?? json['industry'] ?? 'Market';
    return NewsItem(
      title:
          (json['title'] ?? json['headline'] ?? json['name'] ?? 'Market news')
              .toString(),
      sector: sector.toString(),
      time: (json['date'] ?? json['published_at'] ?? json['created_at'] ?? '')
          .toString(),
      url: (json['url'] ?? json['link'] ?? '').toString(),
      source: (json['source'] ?? json['publisher'] ?? 'Sectors Financial API')
          .toString(),
    );
  }
}

class EducationVideo {
  const EducationVideo({
    required this.title,
    required this.topic,
    required this.source,
    required this.views,
    required this.url,
    required this.color,
  });
  final String title;
  final String topic;
  final String source;
  final String views;
  final String url;
  final Color color;
}

const _educationVideos = [
  EducationVideo(
    title: 'Valuation: Intrinsic Value & DCF',
    topic: 'FUNDAMENTAL',
    source: 'Aswath Damodaran',
    views: '500K+ views',
    url:
        'https://www.youtube.com/results?search_query=Aswath+Damodaran+DCF+valuation',
    color: Color(0xFF1F6F4A),
  ),
  EducationVideo(
    title: 'Technical Analysis for Beginners',
    topic: 'TECHNICAL',
    source: 'Rayner Teo',
    views: '500K+ views',
    url:
        'https://www.youtube.com/results?search_query=Rayner+Teo+technical+analysis+for+beginners',
    color: Color(0xFF315B89),
  ),
  EducationVideo(
    title: 'Understanding Risk & Diversification',
    topic: 'RISK MANAGEMENT',
    source: 'The Plain Bagel',
    views: '500K+ views',
    url:
        'https://www.youtube.com/results?search_query=The+Plain+Bagel+investment+risk+diversification',
    color: Color(0xFF805C31),
  ),
];

String _formatPrice(num? value) => value == null
    ? '--'
    : value
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.');
String _formatPercent(double? value) => value == null
    ? '--'
    : '${value >= 0 ? '+' : ''}${(value * 100).toStringAsFixed(2).replaceAll('.', ',')}%';

Map<String, dynamic> normalizeSearchRow(Map<String, dynamic> row) {
  final rawPrice =
      row['price'] ??
      row['last_close_price'] ??
      row['close'] ??
      row['latest_price'];
  final rawChange =
      row['change'] ??
      row['price_change'] ??
      row['percent_change'] ??
      row['change_percent'];
  final price = rawPrice is num ? rawPrice.toDouble() : null;
  final change = rawChange is num ? rawChange.toDouble() : null;

  return {
    ...row,
    'symbol': (row['symbol'] ?? '').toString().replaceAll('.JK', ''),
    'name': (row['name'] ?? row['company_name'] ?? 'Unknown company')
        .toString(),
    'price': price,
    'change': change,
  };
}

void main() => runApp(const StockwiseApp());

class StockwiseApp extends StatelessWidget {
  const StockwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stockwise',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surface,
          indicatorColor: _green,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? _green : _muted,
              fontSize: 12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label wajib diisi' : null;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 56),
                    Text(
                      _isRegister
                          ? 'Mulai jadi investor\nlebih cerdas.'
                          : 'Selamat datang\nkembali.',
                      style: const TextStyle(
                        fontSize: 36,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isRegister
                          ? 'Buat akun gratis dan pahami pasar dengan lebih baik.'
                          : 'Analisis pasar. Temukan peluang. Investasi dengan yakin.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 34),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        final required = _required(value, 'Email');
                        if (required != null) return required;
                        return value!.contains('@')
                            ? null
                            : 'Masukkan email yang valid';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final required = _required(value, 'Password');
                        if (required != null) return required;
                        return value!.length >= 6 ? null : 'Minimal 6 karakter';
                      },
                    ),
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Lupa password?'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isRegister ? 'Buat akun' : 'Masuk',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('atau', style: TextStyle(color: _muted)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Lanjutkan dengan Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: Color(0xFFD9E2DD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _isRegister = !_isRegister),
                        child: Text(
                          _isRegister
                              ? 'Sudah punya akun? Masuk'
                              : 'Belum punya akun? Daftar sekarang',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.show_chart_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      const SizedBox(width: 10),
      const Text(
        'stockwise',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    ],
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    AiScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];
  final _labels = const ['Home', 'Search', 'AI', 'News', 'Profile'];
  final _icons = const [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.auto_awesome_rounded,
    Icons.newspaper_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: _surface,
        indicatorColor: _green,
        height: 76,
        destinations: List.generate(
          _labels.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            selectedIcon: Icon(_icons[index], color: _ink),
            label: _labels[index],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _marketFuture;

  @override
  void initState() {
    super.initState();
    _marketFuture = MarketApi.getSnapshot();
  }

  void _reload() => setState(() => _marketFuture = MarketApi.getSnapshot());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _marketFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _PageScaffold(
          child: Center(child: CircularProgressIndicator(color: _green)),
        );
      }
      if (snapshot.hasError) {
        return _PageScaffold(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: _coral, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Data market belum tersedia',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pastikan backend Agentic_AI dan SECTORS_API_KEY sedang aktif.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      final payload = snapshot.data!;
      final stocks = (payload['data'] as List<dynamic>? ?? [])
          .map((item) => MarketStock.fromJson(item as Map<String, dynamic>))
          .toList();
      final ihsg = payload['ihsg'] as Map<String, dynamic>? ?? {};
      final ihsgPrice = (ihsg['price'] as num?)?.toDouble();
      final ihsgChange = (ihsg['change'] as num?)?.toDouble();
      return _PageScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat pagi,',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cristian 👋',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'IHSG hari ini',
              style: TextStyle(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _surfaceRaised,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indeks Harga Saham Gabungan',
                    style: TextStyle(color: Color(0xFFAABCB3), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ihsgPrice?.toStringAsFixed(2).replaceAll('.', ',') ?? '--',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF285E48),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: Color(0xFF8EE0A9),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatPercent(ihsgChange),
                              style: TextStyle(
                                color: Color(0xFF8EE0A9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        ihsgChange == null
                            ? 'Data belum tersedia'
                            : '${ihsgChange >= 0 ? 'Naik' : 'Turun'} hari ini',
                        style: TextStyle(
                          color: Color(0xFFAABCB3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _MiniChart(),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Watchlist',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Lihat semua')),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: WatchlistStore.instance,
              builder: (context, _) {
                final watchlist = WatchlistStore.instance.stocks;
                final displayed = watchlist.isEmpty
                    ? stocks.take(3).toList()
                    : watchlist;
                return Column(
                  children: displayed
                      .map(
                        (stock) => _StockTile(
                          symbol: stock.symbol,
                          name: stock.name,
                          price: _formatPrice(stock.price),
                          change: _formatPercent(stock.change),
                          positive: (stock.change ?? 0) >= 0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StockDetailScreen(symbol: stock.symbol),
                            ),
                          ),
                          onWatchlist: () =>
                              WatchlistStore.instance.toggle(stock),
                          isWatched: WatchlistStore.instance.contains(
                            stock.symbol,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Belajar investasi',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Materi publik pilihan untuk memahami pasar lebih baik.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 218,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _educationVideos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _EducationVideoCard(video: _educationVideos[index]),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _EducationVideoCard extends StatelessWidget {
  const _EducationVideoCard({required this.video});
  final EducationVideo video;

  Future<void> _openVideo() async {
    final uri = Uri.parse(video.url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 274,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openVideo,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF303030)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 112,
              color: video.color,
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 14,
                    child: Text(
                      video.topic,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    video.source,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: _green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        video.views,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: _muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  String _query = '';
  String _mode = 'stocks';
  late Future<Map<String, dynamic>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = MarketApi.search('');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search(String value) => setState(() {
    _query = value;
    _searchFuture = MarketApi.search(value);
  });

  @override
  Widget build(BuildContext context) => _PageScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        const Text(
          'Market search',
          style: TextStyle(
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data live dari Sectors Financial API.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _queryController,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Cari ticker atau nama perusahaan',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: () => _search(_queryController.text),
              icon: const Icon(Icons.arrow_forward_rounded, color: _green),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'stocks', label: Text('Saham')),
            ButtonSegment(value: 'trending', label: Text('Trending')),
            ButtonSegment(value: 'commodities', label: Text('Komoditas')),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) =>
              setState(() => _mode = selection.first),
        ),
        const SizedBox(height: 24),
        FutureBuilder<Map<String, dynamic>>(
          future: _searchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(color: _green),
                ),
              );
            if (snapshot.hasError)
              return const _SearchMessage(
                text:
                    'Data API belum tersedia. Pastikan backend dan SECTORS_API_KEY aktif.',
              );
            final payload = snapshot.data!;
            if (_mode == 'commodities') {
              final rows = (payload['commodities'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();
              return _AssetList(
                children: rows
                    .map(
                      (row) => _CommodityTile(
                        name: row['name']?.toString() ?? '-',
                        price: row['price'] as num?,
                        date: row['date']?.toString(),
                      ),
                    )
                    .toList(),
              );
            }
            final key = _mode == 'trending' ? 'mostTraded' : 'companies';
            final rows = (payload[key] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();
            return _AssetList(
              children: rows
                  .where(
                    (row) =>
                        _mode == 'trending' ||
                        _query.isEmpty ||
                        '${row['symbol']} ${row['name']}'
                            .toLowerCase()
                            .contains(_query.toLowerCase()),
                  )
                  .map(
                    (row) =>
                        _LiveStockTile(row: row, trending: _mode == 'trending'),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _AssetList extends StatelessWidget {
  const _AssetList({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    children: children.isEmpty
        ? [const _SearchMessage(text: 'Tidak ada data dari API.')]
        : children,
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: _muted),
    ),
  );
}

class _LiveStockTile extends StatelessWidget {
  const _LiveStockTile({required this.row, required this.trending});
  final Map<String, dynamic> row;
  final bool trending;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeSearchRow(row);
    final change = (normalized['change'] as num?)?.toDouble();
    final stock = MarketStock(
      symbol: normalized['symbol']?.toString() ?? '-',
      name: normalized['name']?.toString() ?? '-',
      price: (normalized['price'] as num?)?.toDouble(),
      change: change,
    );

    return AnimatedBuilder(
      animation: WatchlistStore.instance,
      builder: (context, _) => _StockTile(
        symbol: stock.symbol,
        name: stock.name,
        price: _formatPrice(stock.price),
        change: trending
            ? 'Volume ${_formatVolume(normalized['volume'])}'
            : _formatPercent(stock.change),
        positive: (stock.change ?? 0) >= 0,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StockDetailScreen(symbol: stock.symbol),
          ),
        ),
        onWatchlist: () => WatchlistStore.instance.toggle(stock),
        isWatched: WatchlistStore.instance.contains(stock.symbol),
      ),
    );
  }
}

class _CommodityTile extends StatelessWidget {
  const _CommodityTile({
    required this.name,
    required this.price,
    required this.date,
  });
  final String name;
  final num? price;
  final String? date;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.layers_rounded, color: _green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'USD / metric ton • ${date ?? 'latest'}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          price == null ? '--' : '\$${price!.toStringAsFixed(2)}',
          style: const TextStyle(color: _green, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

String _formatVolume(dynamic value) {
  final volume = (value as num?)?.toDouble();
  if (volume == null) return '--';
  if (volume >= 1000000000)
    return '${(volume / 1000000000).toStringAsFixed(1)}B shares';
  if (volume >= 1000000)
    return '${(volume / 1000000).toStringAsFixed(1)}M shares';
  return '${volume.toStringAsFixed(0)} shares';
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
  final String text;
  final bool isUser;
  final bool isError;
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, this.initialPrompt, this.autoSubmit = false});
  final String? initialPrompt;
  final bool autoSubmit;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  Timer? _typingTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      _promptController.text = widget.initialPrompt!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoSubmit &&
          widget.initialPrompt != null &&
          widget.initialPrompt!.trim().isNotEmpty) {
        _askAi();
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _animateAnswer(String answer) async {
    final words = answer.split(RegExp(r'\s+'));
    var visibleText = '';
    for (var index = 0; index < words.length; index++) {
      if (!mounted) return;
      await Future<void>.delayed(Duration(milliseconds: index == 0 ? 80 : 28));
      visibleText += '${index == 0 ? '' : ' '}${words[index]}';
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(
          text: visibleText,
          isUser: false,
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _askAi() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    _promptController.clear();
    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _messages.add(const _ChatMessage(text: '', isUser: false));
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_agentBaseUrl/agent/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw Exception(body['message'] ?? 'Permintaan AI gagal');
      }
      await _animateAnswer(body['data']?.toString() ?? 'Tidak ada jawaban.');
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] = const _ChatMessage(
            text:
                'AI belum dapat dihubungi. Pastikan Agentic_AI berjalan di port 3002.',
            isUser: false,
            isError: true,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) => _PageScaffold(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_aiPanel, Color(0xFF1A5139)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF2C6A4C)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 154,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _AiPanelPainter())),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: _ink,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Text(
                            'AI MARKET DESK',
                            style: TextStyle(
                              color: Color(0xFF9EE6B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x3328D477),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x6655D887),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: _green, size: 7),
                                SizedBox(width: 5),
                                Text(
                                  'ONLINE',
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Your market\nco-pilot.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.03,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Fundamental  •  Technical  •  Risk',
                        style: TextStyle(
                          color: Color(0xFFB9DCC7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChat(
                  onQuestion: (question) {
                    _promptController.text = question;
                    _askAi();
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _ChatBubble(
                    message: _messages[index],
                    isTyping:
                        _isLoading &&
                        index == _messages.length - 1 &&
                        _messages[index].text.isEmpty,
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pertanyaan tentang saham...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isLoading ? null : _askAi,
                style: IconButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _ink,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ink,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AiPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1A9EE6B8)
      ..strokeWidth = 1;
    for (var x = size.width * .58; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 18.0; y < size.height; y += 24) {
      canvas.drawLine(
        Offset(size.width * .55, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    final chartPaint = Paint()
      ..color = const Color(0xAA55D887)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final chart = Path()
      ..moveTo(size.width * .56, size.height * .78)
      ..lineTo(size.width * .64, size.height * .68)
      ..lineTo(size.width * .7, size.height * .73)
      ..lineTo(size.width * .77, size.height * .48)
      ..lineTo(size.width * .84, size.height * .56)
      ..lineTo(size.width * .92, size.height * .27)
      ..lineTo(size.width, size.height * .34);
    canvas.drawPath(chart, chartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onQuestion});
  final ValueChanged<String> onQuestion;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, color: _green, size: 42),
          const SizedBox(height: 14),
          const Text(
            'Mulai percakapan',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Minta AI membedah fundamental, teknikal, atau risiko saham.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                      'Analisis BBCA',
                      'Saham undervalued di IHSG',
                      'Outlook sektor teknologi',
                    ]
                    .map(
                      (question) => ActionChip(
                        label: Text(question),
                        onPressed: () => onQuestion(question),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isTyping});
  final _ChatMessage message;
  final bool isTyping;
  @override
  Widget build(BuildContext context) {
    final color = message.isUser
        ? _green
        : (message.isError ? const Color(0xFF5A2926) : _surface);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 14,
          left: message.isUser ? 42 : 0,
          right: message.isUser ? 0 : 42,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: isTyping
            ? const _TypingDots()
            : Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? _ink : _ink,
                  height: 1.45,
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => Text(
      '.' * (1 + (_controller.value * 3).floor()),
      style: const TextStyle(
        color: _green,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _sector = 'Semua';
  late Future<List<NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = MarketApi.getNews();
  }

  @override
  Widget build(BuildContext context) => _PageScaffold(
    child: FutureBuilder<List<NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: _green));
        if (snapshot.hasError)
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Berita belum tersedia. Pastikan sectors-news-backend berjalan di port 3000 dan quota Sectors tersedia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            ),
          );
        final news = snapshot.data ?? [];
        final sectors = [
          'Semua',
          ...news
              .map((item) => item.sector)
              .where((sector) => sector.isNotEmpty)
              .toSet(),
        ];
        final filteredNews = news
            .where((item) => _sector == 'Semua' || item.sector == _sector)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          children: [
            const Text(
              'Berita pasar',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tetap terinformasi, tetap selangkah lebih maju.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: sectors
                    .map(
                      (sector) => GestureDetector(
                        onTap: () => setState(() => _sector = sector),
                        child: _CategoryChip(
                          label: sector,
                          active: _sector == sector,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (filteredNews.isEmpty)
              const Text(
                'Belum ada berita untuk sektor ini.',
                style: TextStyle(color: _muted),
              ),
            ...filteredNews.map((news) => _LiveNewsCard(news: news)),
          ],
        );
      },
    ),
  );
}

class _LiveNewsCard extends StatelessWidget {
  const _LiveNewsCard({required this.news});
  final NewsItem news;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: news.url.isEmpty
        ? null
        : () async {
            final uri = Uri.tryParse(news.url);
            if (uri != null && await canLaunchUrl(uri))
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
    borderRadius: BorderRadius.circular(19),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  news.sector.toUpperCase(),
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                news.time,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news.title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                news.source,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const Spacer(),
              if (news.url.isNotEmpty)
                const Icon(Icons.open_in_new_rounded, color: _green, size: 16),
            ],
          ),
        ],
      ),
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _mint,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: _green,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cristian Philander',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('christian@email.com', style: TextStyle(color: _muted)),
                ],
              ),
              Spacer(),
              Icon(Icons.edit_outlined, color: _green),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _ProfileOption(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Preferensi investasi',
        ),
        const _ProfileOption(
          icon: Icons.notifications_none_rounded,
          title: 'Notifikasi',
        ),
        const _ProfileOption(
          icon: Icons.security_outlined,
          title: 'Keamanan akun',
        ),
        const _ProfileOption(
          icon: Icons.help_outline_rounded,
          title: 'Pusat bantuan',
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text(
            'Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _MarketBackdrop extends StatelessWidget {
  const _MarketBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MarketBackdropPainter(), child: child);
}

class _MarketBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x0D8AAE9A)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 28.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final candle = Paint()..strokeWidth = 1.2;
    final candles = [
      (0.08, 0.24, 0.18, true),
      (0.15, 0.31, 0.23, false),
      (0.23, 0.2, 0.27, true),
      (0.31, 0.27, 0.19, true),
      (0.39, 0.34, 0.26, false),
      (0.48, 0.22, 0.3, true),
      (0.56, 0.29, 0.21, true),
      (0.64, 0.18, 0.25, false),
      (0.72, 0.25, 0.15, true),
      (0.8, 0.16, 0.2, true),
      (0.88, 0.2, 0.1, false),
    ];
    for (final (x, top, bottom, positive) in candles) {
      final centerX = size.width * x;
      final topY = size.height * top;
      final bottomY = size.height * bottom;
      candle.color = positive
          ? const Color(0x1A55D887)
          : const Color(0x1AE8775D);
      canvas.drawLine(
        Offset(centerX, topY - 16),
        Offset(centerX, bottomY + 16),
        candle,
      );
      canvas.drawRect(
        Rect.fromLTRB(centerX - 5, topY, centerX + 5, bottomY),
        candle,
      );
    }

    final trend = Paint()
      ..color = const Color(0x1855D887)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(0, size.height * .68)
      ..lineTo(size.width * .13, size.height * .63)
      ..lineTo(size.width * .24, size.height * .67)
      ..lineTo(size.width * .36, size.height * .52)
      ..lineTo(size.width * .49, size.height * .57)
      ..lineTo(size.width * .62, size.height * .4)
      ..lineTo(size.width * .76, size.height * .46)
      ..lineTo(size.width * .9, size.height * .26)
      ..lineTo(size.width, size.height * .31);
    canvas.drawPath(path, trend);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    body: SafeArea(child: _MarketBackdrop(child: child)),
  );
}

class _StockTile extends StatelessWidget {
  const _StockTile({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.positive,
    this.onTap,
    this.onWatchlist,
    this.isWatched = false,
  });
  final String symbol, name, price, change;
  final bool positive;
  final VoidCallback? onTap;
  final VoidCallback? onWatchlist;
  final bool isWatched;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(17),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: positive ? _mint : const Color(0xFFFFE7E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                symbol.substring(0, 1),
                style: TextStyle(
                  color: positive ? _green : _coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    style: const TextStyle(color: _muted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp $price',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  change,
                  style: TextStyle(
                    color: positive ? _green : _coral,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onWatchlist != null)
                  IconButton(
                    onPressed: onWatchlist,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isWatched
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isWatched ? _green : _muted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context) => _PageScaffold(
    child: FutureBuilder<Map<String, dynamic>>(
      future: MarketApi.getStockDetail(symbol),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: _green));
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: _coral, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Detail saham belum tersedia',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        final data = snapshot.data!;
        final report = _asMap(data['report']);
        final technical = _asMap(data['technical']);
        final price = (data['price'] as num?);
        final change = (data['change'] as num?)?.toDouble();
        return FutureBuilder<Map<String, String>>(
          future: MarketApi.getBrokerNames(),
          builder: (context, brokerNamesSnapshot) {
            final brokerNames =
                brokerNamesSnapshot.data ?? const <String, String>{};
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['symbol']?.toString() ?? symbol,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.bookmark_border_rounded, color: _green),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF303030)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latest close',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatPercent(change),
                            style: TextStyle(
                              color: (change ?? 0) >= 0 ? _green : _coral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${data['date'] ?? 'latest'}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 110,
                        child: CustomPaint(
                          painter: _HistoryChartPainter(data['history']),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Key metrics',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _MetricGrid(
                  metrics: {
                    'Market cap': _findMetric(report, [
                      'market_cap',
                      'marketCap',
                    ]),
                    'PE TTM': _findMetric(report, ['pe_ttm', 'pe']),
                    'PB MRQ': _findMetric(report, ['pb_mrq', 'pb']),
                    'ROE TTM': _findMetric(report, ['roe_ttm', 'roe']),
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Technical snapshot',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _MetricGrid(
                  metrics: {
                    'RSI': _findMetric(technical, ['rsi', 'RSI']),
                    'MA 20': _findMetric(technical, [
                      'ma20',
                      'moving_average_20',
                    ]),
                    'Support': _findMetric(technical, ['support']),
                    'Resistance': _findMetric(technical, ['resistance']),
                  },
                ),
                const SizedBox(height: 20),
                _BrokerSummaryCard(
                  symbol: data['symbol']?.toString() ?? symbol,
                  brokerNames: brokerNames,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _aiPanel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2C6A4C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: _green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI analyst',
                            style: TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Gabungkan fundamental dan technical data saham ini untuk mendapatkan analisis yang lebih lengkap.',
                        style: TextStyle(color: Color(0xFFB9DCC7), height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiScreen(
                              initialPrompt:
                                  'Analisis ${data['symbol']} secara fundamental dan teknikal berdasarkan data terbaru. Berikan risiko dan kesimpulan.',
                              autoSubmit: true,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Analisis dengan AI'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

String _findMetric(Map<String, dynamic> source, List<String> keys) {
  dynamic find(dynamic value) {
    if (value is Map) {
      for (final entry in value.entries) {
        if (keys.contains(entry.key.toString()) && entry.value != null)
          return entry.value;
        final nested = find(entry.value);
        if (nested != null) return nested;
      }
    } else if (value is List) {
      for (final item in value) {
        final nested = find(item);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  final value = find(source);
  return value == null
      ? '--'
      : value is num
      ? value.toStringAsFixed(2)
      : value.toString();
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final Map<String, String> metrics;
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisExtent: 92,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    children: metrics.entries
        .map(
          (entry) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.value,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _BrokerSummaryCard extends StatelessWidget {
  const _BrokerSummaryCard({required this.symbol, required this.brokerNames});
  final String symbol;
  final Map<String, String> brokerNames;

  static List<Map<String, dynamic>> _normalizeEntries(
    dynamic raw,
    Map<String, String> brokerNames,
  ) {
    final grouped = <String, double>{};

    void collect(dynamic value) {
      if (value is List) {
        for (final item in value) {
          collect(item);
        }
        return;
      }

      if (value is! Map) return;

      final entry = value as Map<String, dynamic>;
      final summary = entry['summary'];
      if (summary is List) {
        for (final item in summary) {
          collect(item);
        }
        return;
      }

      final code = (entry['broker_code'] ?? '').toString();
      if (code.isEmpty) {
        for (final child in entry.values) {
          collect(child);
        }
        return;
      }

      final net = (() {
        if (entry['nval'] != null) return (entry['nval'] as num).toDouble();
        if (entry['net_idr'] != null) return (entry['net_idr'] as num).toDouble();
        if (entry['net'] != null) return (entry['net'] as num).toDouble();
        return 0.0;
      })();

      if (net.abs() > 0) {
        grouped[code] = (grouped[code] ?? 0.0) + net;
      }
    }

    collect(raw);

    final rows = grouped.entries
        .map(
          (entry) => {
            'code': entry.key,
            'name': brokerNames[entry.key] ?? entry.key,
            'net': entry.value,
          },
        )
        .toList();

    rows.sort(
      (a, b) => (b['net'] as double).abs().compareTo((a['net'] as double).abs()),
    );
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: MarketApi.getBrokerSummary(symbol),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: _green)),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final entries = _normalizeEntries(snapshot.data, brokerNames);
        final buyers = entries
            .where((entry) => (entry['net'] as double) > 0)
            .toList();
        final sellers = entries
            .where((entry) => (entry['net'] as double) < 0)
            .toList();

        final buyerMax = buyers.isEmpty
            ? 1.0
            : buyers
                  .map((e) => (e['net'] as double).abs())
                  .reduce((a, b) => a > b ? a : b);
        final sellerMax = sellers.isEmpty
            ? 1.0
            : sellers
                  .map((e) => (e['net'] as double).abs())
                  .reduce((a, b) => a > b ? a : b);
        final maxAbs = buyerMax > sellerMax ? buyerMax : sellerMax;

        final rows = [
          ...buyers
              .take(4)
              .map(
                (entry) => _BrokerTradeRow(
                  name: entry['name'] as String,
                  value: entry['net'] as double,
                  positive: true,
                  maxAbs: maxAbs,
                ),
              ),
          ...sellers
              .take(4)
              .map(
                (entry) => _BrokerTradeRow(
                  name: entry['name'] as String,
                  value: entry['net'] as double,
                  positive: false,
                  maxAbs: maxAbs,
                ),
              ),
        ];

        if (rows.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF303030)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Institutional Trading Activity for ${symbol.toUpperCase()}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Text(
                'Q3 2026',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ...rows,
              const SizedBox(height: 16),
              Row(
                children: [
                  _LegendDot(color: _green),
                  const SizedBox(width: 8),
                  Text(
                    'Institutional Buyer of ${symbol.toUpperCase()}',
                    style: const TextStyle(color: _ink, fontSize: 12),
                  ),
                  const SizedBox(width: 18),
                  _LegendDot(color: _coral),
                  const SizedBox(width: 8),
                  Text(
                    'Institutional Seller of ${symbol.toUpperCase()}',
                    style: const TextStyle(color: _ink, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrokerTradeRow extends StatelessWidget {
  const _BrokerTradeRow({
    required this.name,
    required this.value,
    required this.positive,
    required this.maxAbs,
  });
  final String name;
  final double value;
  final bool positive;
  final double maxAbs;

  @override
  Widget build(BuildContext context) {
    final abs = value.abs();
    final pct = maxAbs == 0 ? 0.0 : (abs / maxAbs).clamp(0.12, 1.0);
    final valueText = _formatMoneyShort(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Align(
              alignment: positive
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                valueText,
                textAlign: TextAlign.right,
                style: const TextStyle(color: _ink, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 180,
            child: Align(
              alignment: positive
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                height: 24,
                width: 180 * pct,
                decoration: BoxDecoration(
                  color: positive
                      ? _green.withValues(alpha: 0.8)
                      : _coral.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

String _formatMoneyShort(double value) {
  if (value.abs() >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

class _HistoryChartPainter extends CustomPainter {
  _HistoryChartPainter(this.history);
  final dynamic history;
  @override
  void paint(Canvas canvas, Size size) {
    final points = history is List ? history.whereType<Map>().toList() : [];
    if (points.length < 2) return;
    final values = points
        .map((row) => (row['close'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1 : max - min;
    final paint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height - ((values[i] - min) / range * (size.height - 12)) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 56, child: CustomPaint(painter: _ChartPainter()));
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8EE0A9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 42)
      ..lineTo(size.width * .12, 36)
      ..lineTo(size.width * .22, 40)
      ..lineTo(size.width * .34, 22)
      ..lineTo(size.width * .45, 29)
      ..lineTo(size.width * .57, 17)
      ..lineTo(size.width * .68, 26)
      ..lineTo(size.width * .78, 13)
      ..lineTo(size.width * .9, 19)
      ..lineTo(size.width, 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      color: active ? _green : _surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? _ink : _muted,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _green),
    ),
    title: Text(
      title,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
  );
}
