import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/teal_background.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// The forgot-password screen.
///
/// The user enters their email and BOB "sends" a reset link (mock). On success
/// the form is replaced by a confirmation with a Resend action, matching the
/// forgot -> resend branch in the wireframes. A real backend swaps in through
/// [AuthService.sendPasswordReset] without touching this screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(passwordResetControllerProvider.notifier).send(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> state = ref.watch(passwordResetControllerProvider);
    final bool isLoading = state.isLoading;
    final bool sent = state.value ?? false;
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
              const SizedBox(height: 4),
              const Center(child: AppLogo(size: 120)),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(color: context.c.surfaceLine),
                  boxShadow: AppColors.cardShadow,
                ),
                child: sent
                    ? _SentState(
                        email: _email.text.trim(),
                        isResending: isLoading,
                        onResend: _submit,
                      )
                    : _FormState(
                        formKey: _formKey,
                        controller: _email,
                        isLoading: isLoading,
                        hasError: state.hasError,
                        onSubmit: _submit,
                      ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.auth),
                  style: TextButton.styleFrom(
                    foregroundColor: context.c.accent,
                  ),
                  child: Text(
                    'Kembali ke halaman masuk',
                    style: text.bodyMedium?.copyWith(
                      color: context.c.accent,
                      fontWeight: FontWeight.w600,
                    ),
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

class _FormState extends StatelessWidget {
  const _FormState({
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.hasError,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Lupa kata sandi',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Masukkan email kamu. Kami akan mengirim tautan untuk mengatur '
            'ulang kata sandi.',
            style: text.bodyMedium?.copyWith(color: context.c.textSecondary),
          ),
          const SizedBox(height: 20),
          if (hasError) ...<Widget>[
            const AuthErrorBanner(
              message: 'Tidak bisa mengirim tautan. Coba lagi sebentar.',
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: AuthValidators.email,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Kirim tautan reset',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState({
    required this.email,
    required this.isResending,
    required this.onResend,
  });

  final String email;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.mark_email_read_outlined,
          color: context.c.bullishOnSurface,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          'Cek email kamu',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          email.isEmpty
              ? 'Tautan untuk mengatur ulang kata sandi telah dikirim.'
              : 'Tautan untuk mengatur ulang kata sandi telah dikirim ke $email.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: context.c.textSecondary),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: isResending ? null : onResend,
          child: isResending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('Kirim ulang tautan'),
        ),
      ],
    );
  }
}
