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

/// The login screen. An off-white form card on the teal canvas with email and
/// password fields, a gold submit button, a Google button, and a link to the
/// sign up screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).signIn(
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

    final String? error = state.hasError ? 'Tidak bisa masuk. Periksa email dan kata sandi, lalu coba lagi.' : null;

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
                        'Masuk',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lanjutkan ke analisis saham kamu.',
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: context.c.accentPress,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Masuk',
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
                    'Belum punya akun?',
                    style: TextStyle(color: context.c.textOnCanvas2),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.signup),
                    style: TextButton.styleFrom(
                      foregroundColor: context.c.accent,
                    ),
                    child: const Text('Daftar'),
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
