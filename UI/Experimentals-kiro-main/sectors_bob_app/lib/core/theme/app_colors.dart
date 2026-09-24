import 'package:flutter/material.dart';

/// Design tokens for BOB.
///
/// Palette rules that must be respected across the app:
/// - Gold accent is for ACTIONS only (buttons, primary calls to action).
/// - Green and red are for DATA signals only (price direction, indicators),
///   never on buttons.
/// - Teal backgrounds are for immersive surfaces (splash, onboarding, chat
///   header), off-white surfaces carry the main light-mode content.
class AppColors {
  const AppColors._();

  // Teal canvas.
  static const Color bgBase = Color(0xFF0B2E2C);
  static const Color bgElevated = Color(0xFF0F3B38);
  static const Color bgSunken = Color(0xFF082523);

  // Off-white surfaces.
  static const Color surface = Color(0xFFF4F1E9);
  static const Color surfaceAlt = Color(0xFFE8E4D8);
  static const Color surfaceLine = Color(0xFFD6D1C4);

  // Text.
  static const Color textOnTeal = Color(0xFFF4F1E9);
  static const Color textOnTeal2 = Color(0xFFA9C4C0);
  static const Color textPrimary = Color(0xFF14312F);
  static const Color textSecondary = Color(0xFF5A6B69);

  // Gold accent, for actions only.
  static const Color accent = Color(0xFFE9B84A);
  static const Color accentPress = Color(0xFFC99A2F);

  /// Dark text placed on top of the gold accent (buttons).
  static const Color textOnAccent = Color(0xFF2A2000);

  // Data signals, never on buttons.
  //
  // Two sets exist because the same signal has to stay readable on two very
  // different canvases:
  //
  // - [bullish]/[bearish] with the *Soft backgrounds are bright text on a
  //   near-black tint, tuned for the dark teal canvas.
  // - [bullishOnSurface]/[bearishOnSurface] with the *Tint backgrounds are
  //   darker text on a light wash, tuned for the off-white surfaces. These
  //   match the badge and metric colors in the palette mock (index.html), where
  //   data on an off-white card reads #12813C green and #C6362C red.
  //
  // Picking the wrong pair is a contrast bug, not just a style slip: the dark
  // *Soft backgrounds turn into near-black blobs when placed on an off-white
  // card. Prefer `SignalBadge(..., onSurface: true)` on off-white.
  static const Color bullish = Color(0xFF22C55E);
  static const Color bullishSoft = Color(0xFF16351F);
  static const Color bearish = Color(0xFFFF5A4D);
  static const Color bearishSoft = Color(0xFF3A1614);
  static const Color neutral = Color(0xFF9AA8A6);

  /// Bullish green darkened for legibility on off-white surfaces.
  static const Color bullishOnSurface = Color(0xFF12813C);

  /// Bearish red darkened for legibility on off-white surfaces.
  static const Color bearishOnSurface = Color(0xFFC6362C);

  /// A 14 percent wash of [bullish], matching `rgba(34,197,94,0.14)` in the
  /// palette mock. Written as an explicit ARGB constant so it stays `const`
  /// and avoids the deprecated `withOpacity`.
  static const Color bullishTint = Color(0x2422C55E);

  /// A 14 percent wash of [bearish], matching `rgba(255,90,77,0.14)`.
  static const Color bearishTint = Color(0x24FF5A4D);

  /// A ~16 percent wash of the gold [accent], used as the active-tab pill in
  /// the bottom navigation so the selected item glows gold without a hard fill.
  static const Color accentTint = Color(0x29E9B84A);

  /// Surface color for the slim bottom navigation bar. A lifted teal that reads
  /// as the bottom edge of the immersive canvas rather than a bright slab, so
  /// the nav no longer clashes with the dark screens above it.
  static const Color navSurface = Color(0xFF0E3835);

  /// Hairline used as the nav bar's top border.
  static const Color navBorder = Color(0xFF10403C);

  // Brand mark colors. These belong to the BOB logo itself (arrow, loop, and
  // paw print), not to data signals, so they are kept separate from bullish
  // and bearish even though the paw print reads as a warm red. Changing the
  // portfolio number or a stock price never uses these.
  static const Color brandMark = Color(0xFF4E9E8B);
  static const Color brandPaw = Color(0xFFB1382B);

  // Radii.
  static const double radiusCard = 18.0;
  static const double radiusSmall = 12.0;
  static const double radiusLarge = 24.0;

  /// Fully rounded pill shape used by primary buttons.
  static const double radiusPill = 999.0;

  /// Soft drop shadow used under off-white cards so they lift off the teal
  /// canvas instead of sitting flush against it. Kept subtle on purpose, this
  /// is a separation cue, not a heavy Material elevation look.
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// A richer, layered card shadow: a tight contact shadow plus a soft, wider
  /// ambient shadow. Two layers read as real depth rather than a flat drop,
  /// which is a big part of moving the cards from "bland" to "premium".
  static const List<BoxShadow> cardShadowRich = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// A faint warm highlight painted along a card's top edge (a hairline of the
  /// off-white pushed lighter) so cards catch a little "light from above".
  static const Color surfaceHighlight = Color(0xFFFBF9F3);
}

/// A consistent spacing scale, in logical pixels, on a 4px base.
///
/// Using named steps instead of scattered magic numbers keeps vertical rhythm
/// even across screens and makes "breathing room" a deliberate choice. Prefer
/// these over raw values in new and refactored layouts.
class AppSpacing {
  const AppSpacing._();

  /// 4 - hairline gaps, icon-to-text.
  static const double xxs = 4.0;

  /// 8 - tight gaps inside a control.
  static const double xs = 8.0;

  /// 12 - default gap between related rows.
  static const double sm = 12.0;

  /// 16 - standard content padding and gaps between cards.
  static const double md = 16.0;

  /// 20 - comfortable screen side padding.
  static const double lg = 20.0;

  /// 24 - generous padding inside hero cards, gaps between sections.
  static const double xl = 24.0;

  /// 32 - large section breaks and bottom scroll padding.
  static const double xxl = 32.0;

  /// 40 - hero spacing, empty-state vertical padding.
  static const double xxxl = 40.0;
}
