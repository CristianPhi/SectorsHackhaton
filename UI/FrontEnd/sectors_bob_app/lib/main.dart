import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_switch_fade.dart';
import 'features/profile/settings_providers.dart';

void main() {
  runApp(const ProviderScope(child: BobApp()));
}

/// Root of the BOB app.
class BobApp extends ConsumerWidget {
  const BobApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // The Profile toggle drives this: true = dark (default), false = light.
    // Both themes are provided and Flutter switches between them by themeMode,
    // so flipping the switch re-themes the whole app instantly.
    final bool isDark = ref.watch(isDarkModeProvider);
    return MaterialApp.router(
      title: 'BOB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      scrollBehavior: const _NoScrollbarBehavior(),
      // Cross-fade the whole app when the theme flips (see ThemeSwitchFade).
      builder: (BuildContext context, Widget? child) {
        return ThemeSwitchFade(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
    );
  }
}

/// Removes the always-on scrollbar track that Material draws on scrollable
/// screens by default. BOB's lists are short and the teal canvas makes the
/// default indicator read as a stray grey stripe, so screens scroll without
/// drawing a track.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
