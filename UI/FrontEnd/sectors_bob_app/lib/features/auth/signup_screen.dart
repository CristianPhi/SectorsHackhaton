import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/user_models.dart';
import '../../services/providers.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// The sign up screen. Mirrors the login layout with an extra name field.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _checkingUsername = false;
  String? _usernameError;
  String? _submitError;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String username = _username.text.trim();
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
      _submitError = null;
    });
    try {
      final bool available =
          await ref.read(authServiceProvider).checkUsernameAvailable(username);
      if (!mounted) return;
      if (!available) {
        setState(() {
          _usernameError =
              'Username sudah diambil, silakan ganti username Anda.';
        });
        return;
      }

      await ref.read(authControllerProvider.notifier).signUp(
            username,
            _name.text,
            _email.text,
            _password.text,
            _confirmPassword.text,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = authErrorMessage(
          error,
          fallback: 'Pendaftaran gagal. Periksa data kamu, lalu coba lagi.',
        );
      });
    } finally {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppUser?> state = ref.watch(authControllerProvider);
    final bool isLoading = state.isLoading || _checkingUsername;

    ref.listen<AsyncValue<AppUser?>>(authControllerProvider, (previous, next) {
      final AppUser? user = next.value;
      if (user != null) {
        context.go(AppRoutes.verifyEmailWith(
          _email.text,
          code: user.developmentCode,
        ));
      }
    });

    final String? error = _submitError ??
        (state.hasError
            ? authErrorMessage(
                state.error,
                fallback:
                    'Pendaftaran gagal. Periksa data kamu, lalu coba lagi.',
              )
            : null);

    return TealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 12),
                const Center(child: AppLogo(size: 132)),
                const SizedBox(height: 28),
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
                          'Daftar',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat akun untuk mulai bertanya ke BOB.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.c.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        if (error != null) ...<Widget>[
                          AuthErrorBanner(message: error),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'contoh: bobanalyst',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) {
                            final String? base = AuthValidators.username(value);
                            if (base != null) return base;
                            if (_usernameError != null) return _usernameError;
                            return null;
                          },
                          onChanged: (_) => setState(() {
                            _usernameError = null;
                            _submitError = null;
                          }),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                            hintText: 'Nama lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: AuthValidators.name,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: AuthValidators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
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
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Ulangi kata sandi',
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
                              value, _password.text),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Daftar',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'atau',
                                style:
                                    TextStyle(color: context.c.textSecondary),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GoogleButton(
                          isLoading: isLoading,
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Sudah punya akun?',
                      style: TextStyle(color: context.c.textOnCanvas2),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.auth),
                      style: TextButton.styleFrom(
                        foregroundColor: context.c.accent,
                      ),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
