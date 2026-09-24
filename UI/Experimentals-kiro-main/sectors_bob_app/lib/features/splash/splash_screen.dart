import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sectors_bob_app/core/theme/app_theme.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/providers.dart';

/// The opening screen. Fades the BOB logo in and out on the teal canvas for a
/// short beat on app startup (before login/signup), then routes to onboarding,
/// or straight to Home when a user is already signed in on the mock.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // A single controller drives the whole fade in -> hold -> fade out beat.
    // The fade-in and fade-out were lengthened by 150% (each ~840ms -> 2100ms)
    // for a slower, more cinematic reveal; the hold in the middle is unchanged.
    // Weights below are in milliseconds so the ratios stay exact:
    //   fade in 2100 + hold 720 + fade out 2100 = 4920ms total.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4920),
    );

    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 2100,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.0),
        weight: 720,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 2100,
      ),
    ]).animate(_controller);

    // Route once the fade in/out cycle has finished playing.
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _goNext();
      }
    });

    _controller.forward();
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    // Synchronous session read. The mock does not persist a session, so this is
    // null on a cold start and we route to onboarding. A real backend that
    // restores a session here would send a returning user straight to Home.
    final bool hasUser = ref.read(authServiceProvider).currentUser() != null;
    context.go(hasUser ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TealBackground(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // A faint gold glow sits behind the mark so the hero moment
                // feels warm rather than floating on flat teal. The Stack sizes
                // itself to its children (no fixed height) so the logo is never
                // clipped, and the logo's own wordmark is hidden here because
                // the splash shows its own tagline just below.
                const Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    GlowBlob(size: 300),
                    AppLogo(size: 180, showWordmark: false),
                  ],
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Analisis saham, dalam bahasa manusia',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.c.textOnCanvas2,
                        fontWeight: FontWeight.w500,
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
