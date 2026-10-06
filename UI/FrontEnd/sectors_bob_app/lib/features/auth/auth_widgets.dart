import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';

String authErrorMessage(Object? error, {required String fallback}) {
  if (error == null) return fallback;

  final String raw = error
      .toString()
      .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '')
      .trim();
  if (raw.startsWith('Request failed:')) {
    final int separator = raw.indexOf(' - ');
    if (separator >= 0) {
      try {
        final dynamic payload = jsonDecode(raw.substring(separator + 3));
        final dynamic message =
            payload is Map<String, dynamic> ? payload['message'] : null;
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        if (message is List) {
          return message.whereType<String>().join('\n');
        }
      } catch (_) {
        // Keep the original response text when the server did not return JSON.
      }
    }
  }

  if (raw.contains('SocketException') ||
      raw.contains('Failed to fetch') ||
      raw.contains('Connection refused')) {
    return 'Tidak dapat terhubung ke backend. Pastikan Agentic_AI dan MongoDB sudah berjalan.';
  }
  return raw.isEmpty ? fallback : raw;
}

/// Field validators shared by the login and sign up forms.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

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

  static String? emailOrUsername(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Email atau username wajib diisi';
    }
    if (input.contains('@')) {
      return email(input);
    }
    if (input.length < 3) {
      return 'Username minimal 3 karakter';
    }
    return null;
  }

  static String? username(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Username wajib diisi';
    }
    if (input.length < 3) {
      return 'Username minimal 3 karakter';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(input)) {
      return 'Username hanya boleh huruf, angka, titik, underscore, dan dash';
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

  static String? confirmPassword(String? value, String? password) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (input != (password ?? '')) {
      return 'Password tidak cocok';
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
