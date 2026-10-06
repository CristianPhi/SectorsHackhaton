import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interfaces/auth_service.dart';
import 'interfaces/chat_service.dart';
import 'interfaces/learn_service.dart';
import 'interfaces/stock_service.dart';
import 'models/user_models.dart';
import 'real/backend_service.dart';

/// Service providers.
///
/// The UI intentionally stays unchanged; only the concrete implementation is
/// swapped to the real backend service.
final Provider<BackendService> backendServiceProvider =
    Provider<BackendService>((ref) {
  final BackendService service = BackendService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<AuthService> authServiceProvider = Provider<AuthService>((ref) {
  final BackendService service = ref.watch(backendServiceProvider);
  return service;
});

final Provider<StockService> stockServiceProvider =
    Provider<StockService>((ref) {
  return ref.watch(backendServiceProvider);
});

final Provider<ChatService> chatServiceProvider = Provider<ChatService>((ref) {
  return ref.watch(backendServiceProvider);
});

final Provider<LearnService> learnServiceProvider =
    Provider<LearnService>((ref) {
  return ref.watch(backendServiceProvider);
});

/// Streams the current authenticated user, or null when signed out.
final StreamProvider<AppUser?> authStateProvider =
    StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authState();
});
