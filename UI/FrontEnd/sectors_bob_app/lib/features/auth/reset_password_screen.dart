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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _code;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _code = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).resetPassword(
            _email.text.trim(),
            _code.text.trim(),
            _password.text,
            _confirmPassword.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password berhasil diubah. Silakan masuk kembali.')),
      );
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
                          'Reset kata sandi',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan email, kode reset, dan password baru Anda.',
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
                            labelText: 'Kode reset',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Kode reset wajib diisi';
                            if (text.length != 6) return 'Kode harus 6 digit';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password baru',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: AuthValidators.password,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Ulangi password baru',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => AuthValidators.confirmPassword(
                            value,
                            _password.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Ubah password',
                          isLoading: _loading,
                          onPressed: _submit,
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
