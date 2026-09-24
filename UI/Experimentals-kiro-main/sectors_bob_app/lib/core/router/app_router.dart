import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/belajar/article_detail_screen.dart';
import '../../features/belajar/belajar_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stock_detail/stock_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/bob_colors.dart';
import 'page_transitions.dart';

/// Route path constants, kept in one place so screens can navigate by name
/// without string typos.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';

  /// Sign up. Navigated to from the login screen.
  static const String signup = '/signup';

  /// Forgot password. Navigated to from the login screen.
  static const String forgotPassword = '/forgot-password';

  /// Belajar tab (videos and news). Replaces the old news route as the first
  /// shell branch.
  static const String belajar = '/belajar';

  /// The in-app article reader. Navigate with '/article/art-ihsg'.
  static const String articlePattern = '/article/:id';
  static String article(String id) => '/article/$id';
  static const String home = '/home';
  static const String ai = '/ai';

  /// Full-screen stock search, pushed from the Home search bar.
  static const String search = '/search';

  /// Profile, pushed from the Home avatar.
  static const String profile = '/profile';

  /// Edit profile, pushed from the profile screen.
  static const String editProfile = '/profile/edit';

  /// Builds the AI tab location, optionally carrying a seed prompt or a ticker
  /// so the chat can open pre-filled. FEAT-003 reads these query parameters.
  static String aiWith({String? seed, String? ticker}) {
    final Map<String, String> query = <String, String>{};
    if (seed != null && seed.trim().isNotEmpty) {
      query['seed'] = seed.trim();
    }
    if (ticker != null && ticker.trim().isNotEmpty) {
      query['ticker'] = ticker.trim();
    }
    if (query.isEmpty) {
      return ai;
    }
    return Uri(path: ai, queryParameters: query).toString();
  }

  /// Stock detail. Navigate with '/stock/BBCA'.
  static const String stockPattern = '/stock/:ticker';
  static String stock(String ticker) => '/stock/$ticker';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorBelajar = GlobalKey<NavigatorState>();
final _shellNavigatorHome = GlobalKey<NavigatorState>();
final _shellNavigatorAi = GlobalKey<NavigatorState>();

/// The app router.
///
/// FEAT-002 and FEAT-003 replace the placeholder builders below with the real
/// screens. The route graph itself is final: splash, onboarding, auth, a
/// three-tab shell (Berita, Beranda, AI), and stock detail.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  // No redirect/auth guard is wired here on purpose: this is a mock-only hero
  // flow demo, so /home, /ai, and /stock/:ticker stay directly reachable for
  // easy walkthroughs. Before shipping a real backend, add a `redirect` that
  // watches authStateProvider and sends unauthenticated users to /auth while
  // keeping the Splash -> Onboarding -> Auth -> Home path intact.
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            AppPageTransitions.fadeThrough(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            AppPageTransitions.fadeThrough(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) =>
            AppPageTransitions.fadeThrough(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            AppPageTransitions.slideUp(state, const SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            AppPageTransitions.slideUp(state, const ForgotPasswordScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _HomeShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBelajar,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.belajar,
                pageBuilder: (context, state) =>
                    AppPageTransitions.fadeThrough(state, const BelajarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHome,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    AppPageTransitions.fadeThrough(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAi,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.ai,
                pageBuilder: (context, state) {
                  final String? seed = state.uri.queryParameters['seed'];
                  final String? ticker = state.uri.queryParameters['ticker'];
                  // A key derived from the seed and ticker remounts the chat
                  // screen when Home or Stock Detail opens it with a new prompt,
                  // which resets and re-seeds the conversation. Without a new
                  // seed the branch stays alive (indexedStack) and an existing
                  // conversation is preserved across tab switches on purpose.
                  return AppPageTransitions.fadeThrough(
                    state,
                    ChatScreen(
                      key: ValueKey<String>('ai-${seed ?? ''}-${ticker ?? ''}'),
                      seed: seed,
                      ticker: ticker,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            AppPageTransitions.slideUp(state, const SearchScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            AppPageTransitions.slideUp(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            AppPageTransitions.slideUp(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.articlePattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final String id = state.pathParameters['id'] ?? '';
          return AppPageTransitions.slideUp(
            state,
            ArticleDetailScreen(articleId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.stockPattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final String ticker = state.pathParameters['ticker'] ?? '';
          return AppPageTransitions.slideUp(
            state,
            StockDetailScreen(ticker: ticker.toUpperCase()),
          );
        },
      ),
    ],
  );
});

/// One destination in the slim bottom navigation.
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<_NavItem> _navItems = <_NavItem>[
  _NavItem(
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
    label: 'Belajar',
  ),
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Beranda',
  ),
  _NavItem(
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    label: 'BOB AI',
  ),
];

/// The three-tab shell. Beranda sits in the center as the hero destination.
///
/// The bottom bar is a slim, dark-teal custom nav (not the tall Material 3
/// NavigationBar) so it reads as the bottom edge of the immersive canvas
/// rather than a bright slab that clashes with the teal screens above. The
/// active tab is marked with a soft gold pill and gold icon/label, which is
/// BOB's action color; inactive tabs use the muted on-teal tone.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _SlimNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}

/// A compact (~62px) dark-teal bottom bar with a gold active state.
class _SlimNavBar extends StatelessWidget {
  const _SlimNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.c.navSurface,
        border: Border(top: BorderSide(color: context.c.navBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _navItems.length; i++)
                Expanded(
                  child: _SlimNavTab(
                    item: _navItems[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tab: an icon over a small label, wrapped in a gold pill when active.
class _SlimNavTab extends StatelessWidget {
  const _SlimNavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? context.c.accent : context.c.textOnCanvas2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      splashColor: context.c.accentTint,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? context.c.accentTint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

