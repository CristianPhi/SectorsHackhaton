import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../interfaces/auth_service.dart';
import '../interfaces/chat_service.dart';
import '../interfaces/learn_service.dart';
import '../interfaces/stock_service.dart';
import '../models/analysis_models.dart';
import '../models/learn_models.dart';
import '../models/stock_models.dart';
import '../models/user_models.dart';

class BackendService
    implements AuthService, StockService, ChatService, LearnService {
  BackendService({String? baseUrl})
      : _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/$'), ''),
        _hasExplicitBaseUrl = baseUrl != null || _apiBaseUrl.isNotEmpty;

  static const List<String> _candidateHosts = <String>[
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  ];
  static List<String> get _candidateUrls => <String>[
        for (int port = 3002; port <= 3021; port++)
          for (final String host in _candidateHosts) 'http://$host:$port',
      ];

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3002',
  );
  static const Duration _cacheTtl = Duration(seconds: 15);

  final String _baseUrl;
  final bool _hasExplicitBaseUrl;
  DateTime? _lastBaseUrlCheck;
  String? _resolvedBaseUrl;
  Future<String>? _baseUrlLookup;
  final Set<String> _favorites = <String>{};
  AppUser? _currentUser;
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  Future<bool> _backendReachable() async {
    try {
      await _activeBaseUrl();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _activeBaseUrl() async {
    final DateTime now = DateTime.now();
    if (_resolvedBaseUrl != null && _lastBaseUrlCheck != null) {
      final Duration elapsed = now.difference(_lastBaseUrlCheck!);
      if (elapsed < _cacheTtl) {
        return _resolvedBaseUrl!;
      }
    }

    final Future<String>? pendingLookup = _baseUrlLookup;
    if (pendingLookup != null) {
      return pendingLookup;
    }

    final Future<String> lookup = _findBaseUrl();
    _baseUrlLookup = lookup;
    try {
      return await lookup;
    } finally {
      if (identical(_baseUrlLookup, lookup)) {
        _baseUrlLookup = null;
      }
    }
  }

  Future<String> _findBaseUrl() async {
    final List<String> candidates = _hasExplicitBaseUrl
        ? <String>[_baseUrl]
        : <String>[
            _baseUrl,
            ..._candidateUrls.where((String url) => url != _baseUrl),
          ];
    for (final String candidate in candidates) {
      try {
        final http.Response response = await http
            .get(Uri.parse('$candidate/health'))
            .timeout(const Duration(milliseconds: 500));
        if (response.statusCode < 500) {
          _resolvedBaseUrl = candidate;
          _lastBaseUrlCheck = DateTime.now();
          return candidate;
        }
      } catch (_) {
        // Server is unreachable. The app must surface the real backend status.
      }
    }

    _resolvedBaseUrl = null;
    _lastBaseUrlCheck = null;
    throw StateError(
      'Backend tidak tersedia. Pastikan Agentic_AI dan MongoDB sudah berjalan.',
    );
  }

  Future<dynamic> _getJson(String path) async {
    final String baseUrl = await _activeBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode >= 400) {
      throw Exception(
          'Request failed: ${response.statusCode} - ${response.body}');
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  List<dynamic> _asList(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map) {
      final dynamic value = payload['value'] ??
          payload['data'] ??
          payload['items'] ??
          payload['results'];
      if (value is List) {
        return value;
      }
    }
    return const <dynamic>[];
  }

  Future<dynamic> _postJson(String path, Map<String, dynamic> body) async {
    final String baseUrl = await _activeBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode >= 400) {
      throw Exception(
          'Request failed: ${response.statusCode} - ${response.body}');
    }
    if (response.body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }

    final data = await _postJson(
      '/auth/login',
      {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    final user = AppUser.fromJson(data);
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String username,
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }

    final data = await _postJson(
      '/auth/register',
      {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    ) as Map<String, dynamic>;
    final user = AppUser.fromJson(data);
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    await _postJson('/auth/verify-email', {'email': email, 'code': code});
  }

  @override
  Future<String?> resendVerification(String email) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final data = await _postJson('/auth/resend-verification', {'email': email});
    if (data is Map<String, dynamic>) {
      return data['developmentCode'] as String?;
    }
    return null;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    throw UnimplementedError('Google auth belum diimplementasikan di backend');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }

    final data =
        await _postJson('/auth/check-username', {'username': username});
    if (data is Map<String, dynamic>) {
      return (data['available'] as bool?) ?? false;
    }
    return false;
  }

  @override
  Future<String?> sendPasswordReset(String email) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final data = await _postJson('/auth/forgot-password', {'email': email});
    if (data is Map<String, dynamic>) {
      return data['developmentCode'] as String?;
    }
    return null;
  }

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String password,
    String confirmPassword,
  ) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    await _postJson('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }

  @override
  Future<AppUser> updateProfile({required String displayName}) async {
    final current = _currentUser;
    if (current == null) {
      throw StateError('Tidak ada pengguna yang masuk.');
    }
    final updated = AppUser(
      id: current.id,
      email: current.email,
      displayName:
          displayName.trim().isEmpty ? current.displayName : displayName,
      isGoogle: current.isGoogle,
    );
    _currentUser = updated;
    _authController.add(updated);
    return updated;
  }

  @override
  AppUser? currentUser() => _currentUser;

  @override
  Stream<AppUser?> authState() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  Future<List<Stock>> localStocks() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final dynamic data = await _getJson('/sectors/stocks');
    final List<dynamic> list = _asList(data);
    return list.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Stock>> favorites() async {
    final Set<String> current = Set<String>.from(_favorites);
    if (current.isNotEmpty) {
      final List<Stock> all = await localStocks();
      return all
          .where((Stock stock) => current.contains(stock.ticker))
          .toList();
    }

    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }

    final dynamic data = await _getJson('/sectors/favorites');
    final List<dynamic> list = _asList(data);
    return list.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Stock>> recentlySearched() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final dynamic data = await _getJson('/sectors/recent');
    final List<dynamic> list = _asList(data);
    return list.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BrokerSummaryEntry>> brokerSummary(String ticker) async {
    if (!(await _backendReachable())) {
      return const <BrokerSummaryEntry>[];
    }

    try {
      final dynamic data =
          await _getJson('/broker/summary/${Uri.encodeComponent(ticker)}');
      final List<dynamic> rows = data is Map && data['data'] is List
          ? (data['data'] as List<dynamic>).expand((dynamic day) {
              if (day is Map && day['summary'] is List) {
                return day['summary'] as List<dynamic>;
              }
              return const <dynamic>[];
            }).toList()
          : _asList(data);
      return rows
          .take(6)
          .map((dynamic item) =>
              BrokerSummaryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <BrokerSummaryEntry>[];
    }
  }

  @override
  Future<StockDetail> detail(String ticker) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final dynamic data = await _getJson('/sectors/stocks/$ticker');
    final Map<String, dynamic> payload =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final StockDetail parsed = StockDetail.fromJson(payload);
    final List<BrokerSummaryEntry> summary = await brokerSummary(ticker);
    return StockDetail(
      stock: parsed.stock,
      description: parsed.description,
      marketCap: parsed.marketCap,
      dayHigh: parsed.dayHigh,
      dayLow: parsed.dayLow,
      sparkline: parsed.sparkline,
      teknikal: parsed.teknikal,
      fundamental: parsed.fundamental,
      berita: parsed.berita,
      brokerSummary: summary.isNotEmpty ? summary : parsed.brokerSummary,
    );
  }

  @override
  Set<String> favoriteTickers() => Set<String>.unmodifiable(_favorites);

  @override
  void addFavorite(String ticker) {
    if (ticker.trim().isEmpty) return;
    _favorites.add(ticker.toUpperCase());
  }

  @override
  void removeFavorite(String ticker) {
    if (ticker.trim().isEmpty) return;
    _favorites.remove(ticker.toUpperCase());
  }

  @override
  Future<List<Stock>> search(String query) async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    final url = query.trim().isEmpty
        ? '/sectors/stocks'
        : '/sectors/search?q=${Uri.encodeQueryComponent(query)}';
    final dynamic data = await _getJson(url);
    final List<dynamic> list = _asList(data);
    return list.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
  }

  String _resolveTicker(String prompt, String? ticker) {
    final String explicit = (ticker ?? '').trim();
    if (explicit.isNotEmpty) {
      return explicit.toUpperCase();
    }
    const List<String> known = <String>['BBCA', 'BBRI', 'BMRI', 'TLKM', 'GOTO'];
    final String upper = prompt.toUpperCase();
    for (final String candidate in known) {
      if (upper.contains(candidate)) {
        return candidate;
      }
    }
    return 'BBCA';
  }

  @override
  Stream<ChatMessage> sendMessage(String prompt, {String? ticker}) async* {
    final String resolvedTicker = _resolveTicker(prompt, ticker);

    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }

    yield ChatMessage.thinking(id: 'thinking');

    try {
      final dynamic payload = await _postJson('/agent/analyze', {
        'prompt': prompt,
        'ticker': resolvedTicker,
      });
      final Map<String, dynamic> data = payload is Map<String, dynamic>
          ? payload
          : (payload is Map
              ? Map<String, dynamic>.from(payload)
              : <String, dynamic>{});
      final dynamic raw =
          data['data'] ?? data['result'] ?? data['message'] ?? payload;

      if (raw is Map<String, dynamic> || raw is Map) {
        final Map<String, dynamic> jsonMap = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);

        final String summary = (jsonMap['summary'] as String?) ??
            'Analisis ${resolvedTicker} berhasil diterima dari backend.';
        final List<dynamic> teknikalJson =
            jsonMap['teknikal'] as List<dynamic>? ?? const <dynamic>[];
        final List<dynamic> fundamentalJson =
            jsonMap['fundamental'] as List<dynamic>? ?? const <dynamic>[];
        final List<dynamic> beritaJson =
            jsonMap['berita'] as List<dynamic>? ?? const <dynamic>[];

        yield ChatMessage.analysis(
          id: 'final',
          analysis: StockAnalysis(
            ticker: (jsonMap['ticker'] as String?) ?? resolvedTicker,
            title: (jsonMap['title'] as String?) ?? 'Analisis $resolvedTicker',
            summary: summary,
            teknikal: teknikalJson
                .map((e) =>
                    TechnicalIndicator.fromJson(e as Map<String, dynamic>))
                .toList(),
            fundamental: fundamentalJson
                .map((e) =>
                    FundamentalMetric.fromJson(e as Map<String, dynamic>))
                .toList(),
            berita: beritaJson
                .map((e) => NewsHeadline.fromJson(e as Map<String, dynamic>))
                .toList(),
            disclaimer: (jsonMap['disclaimer'] as String?) ??
                'Analisis ini bukan rekomendasi beli atau jual. Lakukan riset mandiri sebelum berinvestasi.',
          ),
        );
        return;
      }

      final String messageText = raw is String ? raw : jsonEncode(raw);
      yield ChatMessage.analysis(
        id: 'final',
        analysis: StockAnalysis(
          ticker: resolvedTicker,
          title: 'Analisis $resolvedTicker',
          summary: messageText.length > 220
              ? '${messageText.substring(0, 217).trim()}...'
              : messageText,
          teknikal: const <TechnicalIndicator>[],
          fundamental: const <FundamentalMetric>[],
          berita: const <NewsHeadline>[],
        ),
      );
    } catch (_) {
      yield ChatMessage.analysis(
        id: 'final',
        analysis: StockAnalysis(
          ticker: resolvedTicker,
          title: 'Analisis $resolvedTicker',
          summary:
              'Koneksi AI backend sedang tidak stabil. Silakan coba lagi dalam beberapa detik.',
          teknikal: const <TechnicalIndicator>[],
          fundamental: const <FundamentalMetric>[],
          berita: const <NewsHeadline>[],
        ),
      );
    }
  }

  @override
  Future<List<LearnVideo>> videos() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    try {
      final dynamic data = await _getJson('/learn/videos');
      final List<dynamic> list = _asList(data);
      return list
          .map((e) => LearnVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <LearnVideo>[];
    }
  }

  @override
  Future<List<LearnArticle>> articles() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    try {
      final dynamic data = await _getJson('/api/news');
      final List<dynamic> list = _asList(data);
      return list
          .map((e) => LearnArticle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <LearnArticle>[];
    }
  }

  @override
  Future<List<LearnChannel>> channels() async {
    if (!(await _backendReachable())) {
      throw StateError(
          'Backend tidak tersedia. Hubungkan server Agentic_AI terlebih dahulu.');
    }
    try {
      final dynamic data = await _getJson('/learn/channels');
      final List<dynamic> list = _asList(data);
      return list
          .map((e) => LearnChannel(
                name: (e as Map<String, dynamic>)['name'] as String,
                isVideo: (e['isVideo'] as bool?) ?? false,
              ))
          .toList();
    } catch (_) {
      return const <LearnChannel>[];
    }
  }

  void dispose() {
    _authController.close();
  }
}
