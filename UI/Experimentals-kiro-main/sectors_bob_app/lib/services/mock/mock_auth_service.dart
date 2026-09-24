import 'dart:async';

import '../interfaces/auth_service.dart';
import '../models/user_models.dart';

/// In-memory mock auth. Simulates network latency and keeps a broadcast stream
/// so the router can react to sign-in and sign-out.
class MockAuthService implements AuthService {
  MockAuthService();

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _current;

  static const Duration _latency = Duration(milliseconds: 900);

  String _nameFromEmail(String email) {
    final String local = email.contains('@') ? email.split('@').first : email;
    if (local.isEmpty) {
      return 'Investor';
    }
    final String cleaned = local.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(_latency);
    final AppUser user = AppUser(
      id: 'user-${email.hashCode.toUnsigned(20)}',
      email: email,
      displayName: _nameFromEmail(email),
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    await Future<void>.delayed(_latency);
    final AppUser user = AppUser(
      id: 'user-${email.hashCode.toUnsigned(20)}',
      email: email,
      displayName: name.trim().isEmpty ? _nameFromEmail(email) : name.trim(),
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(_latency);
    const AppUser user = AppUser(
      id: 'google-mock-001',
      email: 'investor@gmail.com',
      displayName: 'Investor Google',
      isGoogle: true,
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // No real email is sent from the mock. It only simulates the round trip so
    // the forgot-password screen can show its sending and sent states.
    await Future<void>.delayed(_latency);
  }

  @override
  Future<AppUser> updateProfile({required String displayName}) async {
    await Future<void>.delayed(_latency);
    final AppUser? existing = _current;
    if (existing == null) {
      throw StateError('Tidak ada pengguna yang masuk.');
    }
    final AppUser updated = AppUser(
      id: existing.id,
      email: existing.email,
      displayName: displayName.trim().isEmpty
          ? existing.displayName
          : displayName.trim(),
      isGoogle: existing.isGoogle,
    );
    _current = updated;
    _controller.add(updated);
    return updated;
  }

  @override
  AppUser? currentUser() => _current;

  @override
  Stream<AppUser?> authState() async* {
    // Replay the current value to every new subscriber first. The broadcast
    // controller alone does not retain its last event, so a listener that
    // subscribes after sign-in (for example the Profile screen opening later)
    // would otherwise sit in a loading state until the next change. Yielding
    // [_current] up front keeps late subscribers in sync.
    yield _current;
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
