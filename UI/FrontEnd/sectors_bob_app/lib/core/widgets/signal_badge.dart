import 'package:flutter/material.dart';

import '../../services/models/analysis_models.dart';
import '../theme/app_colors.dart';
import '../theme/bob_colors.dart';

/// The visual kind of a signal badge, decoupled from the concrete colors so the
/// badge can resolve mode-aware colors at build time.
enum _BadgeKind { positive, negative, neutral }

/// A pill badge for DATA signals only.
///
/// Maps a [Signal] or [Sentiment] to a soft background and data-colored text
/// (green for bullish/positive, red for bearish/negative, muted for neutral).
/// These colors are for data and must never appear on action buttons.
///
/// Set [onSurface] to true when the badge sits on an off-white surface (a
/// surface card, chat bubble, or metric row). It swaps to the darker on-surface
/// data colors over a light tint. On the immersive canvas leave it false for
/// the brighter pair. Colors are resolved from the active theme so the badge
/// adapts to light and dark mode.
class SignalBadge extends StatelessWidget {
  const SignalBadge._({
    required this.label,
    required this.kind,
    required this.onSurface,
    this.icon,
  });

  /// Builds a badge from an analysis [Signal].
  factory SignalBadge.signal(Signal signal,
      {String? label, bool onSurface = false}) {
    switch (signal) {
      case Signal.bullish:
        return SignalBadge._(
          label: label ?? 'Bullish',
          kind: _BadgeKind.positive,
          onSurface: onSurface,
          icon: Icons.trending_up,
        );
      case Signal.bearish:
        return SignalBadge._(
          label: label ?? 'Bearish',
          kind: _BadgeKind.negative,
          onSurface: onSurface,
          icon: Icons.trending_down,
        );
      case Signal.netral:
        return SignalBadge._(
          label: label ?? 'Netral',
          kind: _BadgeKind.neutral,
          onSurface: onSurface,
          icon: Icons.trending_flat,
        );
    }
  }

  /// Builds a badge from a news [Sentiment].
  factory SignalBadge.sentiment(Sentiment sentiment, {bool onSurface = false}) {
    switch (sentiment) {
      case Sentiment.positif:
        return SignalBadge._(
          label: 'Positif',
          kind: _BadgeKind.positive,
          onSurface: onSurface,
        );
      case Sentiment.negatif:
        return SignalBadge._(
          label: 'Negatif',
          kind: _BadgeKind.negative,
          onSurface: onSurface,
        );
      case Sentiment.netral:
        return SignalBadge._(
          label: 'Netral',
          kind: _BadgeKind.neutral,
          onSurface: onSurface,
        );
    }
  }

  /// Builds a badge for a percent change value. Positive reads bullish, negative
  /// reads bearish. This shows data only, never an instruction.
  factory SignalBadge.change({
    required double changePercent,
    required String label,
    bool onSurface = false,
  }) {
    if (changePercent > 0) {
      return SignalBadge._(
        label: label,
        kind: _BadgeKind.positive,
        onSurface: onSurface,
        icon: Icons.arrow_drop_up,
      );
    }
    if (changePercent < 0) {
      return SignalBadge._(
        label: label,
        kind: _BadgeKind.negative,
        onSurface: onSurface,
        icon: Icons.arrow_drop_down,
      );
    }
    return SignalBadge._(
      label: label,
      kind: _BadgeKind.neutral,
      onSurface: onSurface,
    );
  }

  final String label;
  final _BadgeKind kind;
  final bool onSurface;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final BobColors c = context.c;
    late final Color background;
    late final Color foreground;
    switch (kind) {
      case _BadgeKind.positive:
        background = onSurface ? c.bullishTint : c.bullishSoft;
        foreground = onSurface ? c.bullishOnSurface : c.bullish;
      case _BadgeKind.negative:
        background = onSurface ? c.bearishTint : c.bearishSoft;
        foreground = onSurface ? c.bearishOnSurface : c.bearish;
      case _BadgeKind.neutral:
        background = c.surfaceAlt;
        foreground = c.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
