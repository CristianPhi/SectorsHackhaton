import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared page-transition builders so every route in the app animates in a
/// consistent way instead of snapping between screens.
///
/// [fadeThrough] is the default for top-level destinations (splash, onboarding,
/// auth, home shell): the incoming screen fades in while scaling up a hair, for
/// a soft "materialize" feel. [slideUp] is used for pushed detail screens
/// (search, profile, stock detail, article) so they feel like they come from
/// the bottom, matching a drill-in mental model.
class AppPageTransitions {
  const AppPageTransitions._();

  static const Duration _duration = Duration(milliseconds: 320);
  static const Duration _reverseDuration = Duration(milliseconds: 240);

  /// A fade + gentle scale. Good for switching between peer destinations.
  static CustomTransitionPage<void> fadeThrough(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: _duration,
      reverseTransitionDuration: _reverseDuration,
      child: child,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// A fade + slide from the bottom. Good for pushed detail screens.
  static CustomTransitionPage<void> slideUp(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: _duration,
      reverseTransitionDuration: _reverseDuration,
      child: child,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
