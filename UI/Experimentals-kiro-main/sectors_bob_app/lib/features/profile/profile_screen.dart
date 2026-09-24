import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/user_models.dart';
import '../../services/providers.dart';
import 'settings_providers.dart';

/// The Profile screen, pushed from the Home avatar.
///
/// Shows the signed-in user's details, a settings block (edit profile, theme,
/// language), and a sign out action. The theme and language toggles are live
/// state but do not repaint the app yet: BOB is dark-first, so the controls are
/// present and honest ("Mode terang segera hadir") rather than faked.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(authStateProvider).value;
    final bool isDark = ref.watch(isDarkModeProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return TealBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.c.textOnCanvas,
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            _ProfileHeader(user: user),
            const SizedBox(height: 24),
            const _SectionLabel(text: 'Akun'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: <Widget>[
                _SettingsRow(
                  icon: Icons.person_outline,
                  label: 'Edit profil',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.c.textSecondary,
                  ),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  trailing: Text(
                    user?.email ?? '-',
                    style: text.bodyMedium?.copyWith(
                      color: context.c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel(text: 'Preferensi'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: <Widget>[
                _SettingsRow(
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  label: isDark ? 'Mode gelap' : 'Mode terang',
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: context.c.accent,
                    onChanged: (bool v) =>
                        ref.read(isDarkModeProvider.notifier).setDark(v),
                  ),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.translate_outlined,
                  label: 'Bahasa',
                  trailing: _LanguagePicker(
                    value: language,
                    onChanged: (AppLanguage v) =>
                        ref.read(languageProvider.notifier).set(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.textOnCanvas,
                side: BorderSide(color: context.c.textOnCanvas2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'BOB v1.0.0  .  DYOR selalu berlaku',
                style: text.bodySmall?.copyWith(color: context.c.textOnCanvas2),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = user?.displayName ?? 'Investor';
    final String initials = _initials(name);
    return Row(
      children: <Widget>[
        Container(
          height: 64,
          width: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.c.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: TextStyle(
              color: context.c.textOnAccent,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: text.titleLarge?.copyWith(
                  color: context.c.textOnCanvas,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? 'Belum masuk',
                style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
              ),
              if (user?.isGoogle ?? false) ...<Widget>[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.c.bgElevated,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    border: Border.all(color: context.c.bgSunken),
                  ),
                  child: Text(
                    'Akun Google',
                    style: text.bodySmall?.copyWith(
                      color: context.c.textOnCanvas2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'IN';
    }
    if (parts.length == 1) {
      final String p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.c.textOnCanvas2,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.surfaceLine),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: context.c.textPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: text.bodyLarge?.copyWith(
                      color: context.c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: text.bodySmall
                          ?.copyWith(color: context.c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, endIndent: 16);
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AppLanguage>(
      value: value,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      onChanged: (AppLanguage? v) {
        if (v != null) {
          onChanged(v);
        }
      },
      items: const <DropdownMenuItem<AppLanguage>>[
        DropdownMenuItem<AppLanguage>(
          value: AppLanguage.indonesia,
          child: Text('Indonesia'),
        ),
        DropdownMenuItem<AppLanguage>(
          value: AppLanguage.english,
          child: Text('English'),
        ),
      ],
    );
  }
}
