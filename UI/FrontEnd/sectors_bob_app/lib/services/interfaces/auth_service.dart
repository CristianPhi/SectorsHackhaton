import '../models/user_models.dart';

/// Authentication contract. The mock implementation lives under services/mock.
/// A real backend implementation can replace it without touching the UI.
abstract class AuthService {
  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> signUpWithEmail(
    String username,
    String name,
    String email,
    String password,
    String confirmPassword,
  );

  Future<bool> checkUsernameAvailable(String username);

  Future<void> verifyEmail(String email, String code);

  Future<String?> resendVerification(String email);

  Future<String?> sendPasswordReset(String email);

  Future<void> resetPassword(
    String email,
    String code,
    String password,
    String confirmPassword,
  );

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

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
