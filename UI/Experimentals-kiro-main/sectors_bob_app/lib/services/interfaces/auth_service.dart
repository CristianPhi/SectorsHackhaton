import '../models/user_models.dart';

/// Authentication contract. The mock implementation lives under services/mock.
/// A real backend implementation can replace it without touching the UI.
abstract class AuthService {
  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> signUpWithEmail(String email, String password, String name);

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

  /// Sends a password reset link to [email]. The mock only simulates latency
  /// and always resolves; a real backend would trigger the reset email and may
  /// throw on an unknown address.
  Future<void> sendPasswordReset(String email);

  /// Updates the signed-in user's editable profile fields and returns the
  /// updated user. Currently only [displayName] is editable. Throws a
  /// [StateError] when no user is signed in.
  Future<AppUser> updateProfile({required String displayName});

  /// The current user read synchronously, or null when signed out. Splash uses
  /// this to decide whether to skip onboarding. The mock does not persist a
  /// session across launches, so it returns null on a cold start.
  AppUser? currentUser();

  /// Emits the current user, or null when signed out.
  Stream<AppUser?> authState();
}
