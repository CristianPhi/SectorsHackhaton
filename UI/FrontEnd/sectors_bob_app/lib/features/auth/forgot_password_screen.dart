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
    final String? developmentCode =
        ref.read(passwordResetControllerProvider.notifier).developmentCode;
    final String? errorMessage = state.hasError
        ? authErrorMessage(
            state.error,
            fallback: 'Tidak bisa mengirim kode reset. Coba lagi sebentar.',
          )
        : null;
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
                          developmentCode: developmentCode,
                          isResending: isLoading,
                          onResend: _submit,
                          onContinue: () => context.go(
                            AppRoutes.resetPasswordWith(_email.text.trim()),
                          ),
                        )
                      : _FormState(
                          formKey: _formKey,
                          controller: _email,
                          isLoading: isLoading,
                          errorMessage: errorMessage,
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
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
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
            'Masukkan email kamu untuk menerima kode reset kata sandi.',
            style: text.bodyMedium?.copyWith(color: context.c.textSecondary),
          ),
          const SizedBox(height: 20),
          if (errorMessage != null) ...<Widget>[
            AuthErrorBanner(message: errorMessage!),
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
            label: 'Kirim kode reset',
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
    required this.developmentCode,
    required this.isResending,
    required this.onResend,
    required this.onContinue,
  });

  final String email;
  final String? developmentCode;
  final bool isResending;
  final VoidCallback onResend;
  final VoidCallback onContinue;

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
          developmentCode != null
              ? 'SMTP tidak tersedia. Gunakan kode reset lokal ini.'
              : email.isEmpty
                  ? 'Kode untuk mengatur ulang kata sandi telah dikirim.'
                  : 'Kode reset telah dikirim ke $email.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: context.c.textSecondary),
        ),
        if (developmentCode != null) ...<Widget>[
          const SizedBox(height: 10),
          SelectableText(
            developmentCode!,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Masukkan kode reset',
          isLoading: false,
          onPressed: onContinue,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: isResending ? null : onResend,
          child: isResending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('Kirim ulang kode'),
        ),
      ],
    );
  }
}
