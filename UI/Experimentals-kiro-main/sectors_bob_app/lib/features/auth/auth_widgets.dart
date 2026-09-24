import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';

/// Field validators shared by the login and sign up forms.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailPattern.hasMatch(input)) {
      return 'Format email belum benar';
    }
    return null;
  }

  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (input.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  static String? name(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }
}

/// The gold Google sign in button. It is an action, so it uses the gold accent
/// with dark text like every other primary action.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.c.textPrimary,
          side: BorderSide(color: context.c.surfaceLine),
          backgroundColor: context.c.surface,
        ),
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Masuk dengan Google'),
      ),
    );
  }
}

/// An inline error banner shown when an auth attempt fails.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.c.bearishSoft,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: context.c.bearish, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.c.bearish,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
