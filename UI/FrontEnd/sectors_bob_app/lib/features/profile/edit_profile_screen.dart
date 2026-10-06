import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/user_models.dart';
import '../../services/providers.dart';
import '../auth/auth_widgets.dart';

/// Edit profile, pushed from the Profile screen.
///
/// Currently the display name is the only editable field. Saving writes through
/// [AuthService.updateProfile], which republishes the user on the auth stream
/// so the Profile screen and Home avatar update on return.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final AppUser? user = ref.read(authStateProvider).value;
    _name = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .updateProfile(displayName: _name.text.trim());
      if (mounted) {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Tidak bisa menyimpan perubahan. Coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppUser? user = ref.watch(authStateProvider).value;

    return TealBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.c.textOnCanvas,
        elevation: 0,
        title: const Text('Edit profil'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
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
                  if (_error != null) ...<Widget>[
                    AuthErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: AuthValidators.name,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    enabled: false,
                    initialValue: user?.email ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email tidak dapat diubah pada versi ini.',
                    style: text.bodySmall
                        ?.copyWith(color: context.c.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Simpan',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
