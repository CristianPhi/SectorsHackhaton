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
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).signUp(
            _name.text,
            _email.text,
            _password.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppUser?> state = ref.watch(authControllerProvider);
    final bool isLoading = state.isLoading;

    ref.listen<AsyncValue<AppUser?>>(authControllerProvider, (previous, next) {
      if (next.value != null) {
        context.go(AppRoutes.home);
      }
    });

    final String? error = state.hasError
        ? 'Pendaftaran gagal. Periksa data kamu, lalu coba lagi.'
        : null;

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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.c.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (error != null) ...<Widget>[
                        AuthErrorBanner(message: error),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
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
                        textInputAction: TextInputAction.done,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => _submit(),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'atau',
                              style: TextStyle(color: context.c.textSecondary),
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
