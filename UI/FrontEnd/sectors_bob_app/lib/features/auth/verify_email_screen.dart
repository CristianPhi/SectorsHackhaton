import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/providers.dart';
import 'auth_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.initialEmail,
    this.initialCode,
  });

  final String initialEmail;
  final String? initialCode;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _code;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _code = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .verifyEmail(_email.text.trim(), _code.text.trim());
      if (!mounted) return;
      context.go(AppRoutes.auth);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      final String? developmentCode = await ref
          .read(authServiceProvider)
          .resendVerification(_email.text.trim());
      if (mounted) {
        if (developmentCode != null) {
          setState(() => _code.text = developmentCode);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              developmentCode == null
                  ? 'Kode verifikasi baru telah dikirim.'
                  : 'Kode verifikasi lokal: $developmentCode',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return TealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: context.c.textOnCanvas,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(child: AppLogo(size: 120)),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    border: Border.all(color: context.c.surfaceLine),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Verifikasi email',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan email dan kode 6 digit yang dikirim ke inbox Anda.',
                          style: text.bodyMedium
                              ?.copyWith(color: context.c.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...<Widget>[
                          AuthErrorBanner(message: _error!),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) => AuthValidators.email(value),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Kode verifikasi',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty)
                              return 'Kode verifikasi wajib diisi';
                            if (text.length != 6) return 'Kode harus 6 digit';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Verifikasi',
                          isLoading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loading ? null : _resend,
                          child: const Text('Kirim ulang kode'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
