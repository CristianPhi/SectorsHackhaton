import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interfaces/auth_service.dart';
import 'interfaces/chat_service.dart';
import 'interfaces/learn_service.dart';
import 'interfaces/stock_service.dart';
import 'mock/mock_auth_service.dart';
import 'mock/mock_chat_service.dart';
import 'mock/mock_learn_service.dart';
import 'mock/mock_stock_service.dart';
import 'models/user_models.dart';

/// Service providers.
///
/// Each provider is bound to a mock implementation. When a real backend is
/// ready, override these providers in the ProviderScope and the UI stays
/// untouched.
final Provider<AuthService> authServiceProvider = Provider<AuthService>((ref) {
  final MockAuthService service = MockAuthService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<StockService> stockServiceProvider = Provider<StockService>((ref) {
  return MockStockService();
});

final Provider<ChatService> chatServiceProvider = Provider<ChatService>((ref) {
  return MockChatService();
});

final Provider<LearnService> learnServiceProvider = Provider<LearnService>((ref) {
  return MockLearnService();
});

/// Streams the current authenticated user, or null when signed out.
final StreamProvider<AppUser?> authStateProvider =
    StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authState();
});
