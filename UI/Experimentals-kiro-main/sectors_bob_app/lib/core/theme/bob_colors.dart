import 'package:flutter/material.dart';

import 'darkmode/dark_palette.dart';
import 'lightmode/light_palette.dart';

/// The semantic color contract shared by both modes.
///
/// Screens read these tokens through the theme (see the [BobColorsX] context
/// extension) instead of referencing a fixed palette, so flipping light/dark
/// re-themes the whole app. [BobColors.dark] and [BobColors.light] build the
/// token set from darkmode/ and lightmode/ palette files respectively.
///
/// Only mode-dependent *colors* live here. Geometry (radii), the data-signal
/// hues that stay constant, and shadows remain compile-time constants in
/// AppColors so they can be used in `const` widgets without a context lookup.
@immutable
class BobColors extends ThemeExtension<BobColors> {
  const BobColors({
    required this.brightness,
    required this.bgBase,
    required this.bgElevated,
    required this.bgSunken,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceLine,
    required this.surfaceHighlight,
    required this.textOnCanvas,
    required this.textOnCanvas2,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentPress,
    required this.textOnAccent,
    required this.accentTint,
    required this.bullish,
    required this.bullishSoft,
    required this.bearish,
    required this.bearishSoft,
    required this.neutral,
    required this.bullishOnSurface,
    required this.bearishOnSurface,
    required this.bullishTint,
    required this.bearishTint,
    required this.navSurface,
    required this.navBorder,
    required this.grainLight,
    required this.grainDark,
    required this.dot,
    required this.canvasGradient,
  });

  /// Whether this token set is the dark mode set. Handy for the rare widget
  /// that needs to branch on mode directly (e.g. a status-bar icon brightness).
  final Brightness brightness;

  // Canvas.
  final Color bgBase;
  final Color bgElevated;
  final Color bgSunken;

  // Surfaces.
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceLine;
  final Color surfaceHighlight;

  // Text. `onCanvas`/`onCanvas2` are for text placed directly on the app
  // background; `primary`/`secondary` are for text on a card/surface.
  final Color textOnCanvas;
  final Color textOnCanvas2;
  final Color textPrimary;
  final Color textSecondary;

  // Gold action accent.
  final Color accent;
  final Color accentPress;
  final Color textOnAccent;
  final Color accentTint;

  // Data signals.
  final Color bullish;
  final Color bullishSoft;
  final Color bearish;
  final Color bearishSoft;
  final Color neutral;
  final Color bullishOnSurface;
  final Color bearishOnSurface;
  final Color bullishTint;
  final Color bearishTint;

  // Bottom navigation.
  final Color navSurface;
  final Color navBorder;

  // Background texture.
  final Color grainLight;
  final Color grainDark;
  final Color dot;
  final List<Color> canvasGradient;

  bool get isDark => brightness == Brightness.dark;

  /// The dark (teal-first) token set.
  static const BobColors dark = BobColors(
    brightness: Brightness.dark,
    bgBase: DarkPalette.bgBase,
    bgElevated: DarkPalette.bgElevated,
    bgSunken: DarkPalette.bgSunken,
    surface: DarkPalette.surface,
    surfaceAlt: DarkPalette.surfaceAlt,
    surfaceLine: DarkPalette.surfaceLine,
    surfaceHighlight: DarkPalette.surfaceHighlight,
    textOnCanvas: DarkPalette.textOnCanvas,
    textOnCanvas2: DarkPalette.textOnCanvas2,
    textPrimary: DarkPalette.textPrimary,
    textSecondary: DarkPalette.textSecondary,
    accent: DarkPalette.accent,
    accentPress: DarkPalette.accentPress,
    textOnAccent: DarkPalette.textOnAccent,
    accentTint: DarkPalette.accentTint,
    bullish: DarkPalette.bullish,
    bullishSoft: DarkPalette.bullishSoft,
    bearish: DarkPalette.bearish,
    bearishSoft: DarkPalette.bearishSoft,
    neutral: DarkPalette.neutral,
    bullishOnSurface: DarkPalette.bullishOnSurface,
    bearishOnSurface: DarkPalette.bearishOnSurface,
    bullishTint: DarkPalette.bullishTint,
    bearishTint: DarkPalette.bearishTint,
    navSurface: DarkPalette.navSurface,
    navBorder: DarkPalette.navBorder,
    grainLight: DarkPalette.grainLight,
    grainDark: DarkPalette.grainDark,
    dot: DarkPalette.dot,
    canvasGradient: DarkPalette.canvasGradient,
  );

  /// The light (warm off-white) token set.
  static const BobColors light = BobColors(
    brightness: Brightness.light,
    bgBase: LightPalette.bgBase,
    bgElevated: LightPalette.bgElevated,
    bgSunken: LightPalette.bgSunken,
    surface: LightPalette.surface,
    surfaceAlt: LightPalette.surfaceAlt,
    surfaceLine: LightPalette.surfaceLine,
    surfaceHighlight: LightPalette.surfaceHighlight,
    textOnCanvas: LightPalette.textOnCanvas,
    textOnCanvas2: LightPalette.textOnCanvas2,
    textPrimary: LightPalette.textPrimary,
    textSecondary: LightPalette.textSecondary,
    accent: LightPalette.accent,
    accentPress: LightPalette.accentPress,
    textOnAccent: LightPalette.textOnAccent,
    accentTint: LightPalette.accentTint,
    bullish: LightPalette.bullish,
    bullishSoft: LightPalette.bullishSoft,
    bearish: LightPalette.bearish,
    bearishSoft: LightPalette.bearishSoft,
    neutral: LightPalette.neutral,
    bullishOnSurface: LightPalette.bullishOnSurface,
    bearishOnSurface: LightPalette.bearishOnSurface,
    bullishTint: LightPalette.bullishTint,
    bearishTint: LightPalette.bearishTint,
    navSurface: LightPalette.navSurface,
    navBorder: LightPalette.navBorder,
    grainLight: LightPalette.grainLight,
    grainDark: LightPalette.grainDark,
    dot: LightPalette.dot,
    canvasGradient: LightPalette.canvasGradient,
  );

  @override
  BobColors copyWith({
    Brightness? brightness,
    Color? bgBase,
    Color? bgElevated,
    Color? bgSunken,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceLine,
    Color? surfaceHighlight,
    Color? textOnCanvas,
    Color? textOnCanvas2,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentPress,
    Color? textOnAccent,
    Color? accentTint,
    Color? bullish,
    Color? bullishSoft,
    Color? bearish,
    Color? bearishSoft,
    Color? neutral,
    Color? bullishOnSurface,
    Color? bearishOnSurface,
    Color? bullishTint,
    Color? bearishTint,
    Color? navSurface,
    Color? navBorder,
    Color? grainLight,
    Color? grainDark,
    Color? dot,
    List<Color>? canvasGradient,
  }) {
    return BobColors(
      brightness: brightness ?? this.brightness,
      bgBase: bgBase ?? this.bgBase,
      bgElevated: bgElevated ?? this.bgElevated,
      bgSunken: bgSunken ?? this.bgSunken,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceLine: surfaceLine ?? this.surfaceLine,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      textOnCanvas: textOnCanvas ?? this.textOnCanvas,
      textOnCanvas2: textOnCanvas2 ?? this.textOnCanvas2,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentPress: accentPress ?? this.accentPress,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accentTint: accentTint ?? this.accentTint,
      bullish: bullish ?? this.bullish,
      bullishSoft: bullishSoft ?? this.bullishSoft,
      bearish: bearish ?? this.bearish,
      bearishSoft: bearishSoft ?? this.bearishSoft,
      neutral: neutral ?? this.neutral,
      bullishOnSurface: bullishOnSurface ?? this.bullishOnSurface,
      bearishOnSurface: bearishOnSurface ?? this.bearishOnSurface,
      bullishTint: bullishTint ?? this.bullishTint,
      bearishTint: bearishTint ?? this.bearishTint,
      navSurface: navSurface ?? this.navSurface,
      navBorder: navBorder ?? this.navBorder,
      grainLight: grainLight ?? this.grainLight,
      grainDark: grainDark ?? this.grainDark,
      dot: dot ?? this.dot,
      canvasGradient: canvasGradient ?? this.canvasGradient,
    );
  }

  @override
  BobColors lerp(ThemeExtension<BobColors>? other, double t) {
    if (other is! BobColors) {
      return this;
    }
    return BobColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceLine: Color.lerp(surfaceLine, other.surfaceLine, t)!,
      surfaceHighlight: Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      textOnCanvas: Color.lerp(textOnCanvas, other.textOnCanvas, t)!,
      textOnCanvas2: Color.lerp(textOnCanvas2, other.textOnCanvas2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPress: Color.lerp(accentPress, other.accentPress, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      bullish: Color.lerp(bullish, other.bullish, t)!,
      bullishSoft: Color.lerp(bullishSoft, other.bullishSoft, t)!,
      bearish: Color.lerp(bearish, other.bearish, t)!,
      bearishSoft: Color.lerp(bearishSoft, other.bearishSoft, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      bullishOnSurface:
          Color.lerp(bullishOnSurface, other.bullishOnSurface, t)!,
      bearishOnSurface:
          Color.lerp(bearishOnSurface, other.bearishOnSurface, t)!,
      bullishTint: Color.lerp(bullishTint, other.bullishTint, t)!,
      bearishTint: Color.lerp(bearishTint, other.bearishTint, t)!,
      navSurface: Color.lerp(navSurface, other.navSurface, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      grainLight: Color.lerp(grainLight, other.grainLight, t)!,
      grainDark: Color.lerp(grainDark, other.grainDark, t)!,
      dot: Color.lerp(dot, other.dot, t)!,
      canvasGradient: t < 0.5 ? canvasGradient : other.canvasGradient,
    );
  }
}

/// Convenient access to the active [BobColors] from any widget:
/// `context.c.surface`, `context.c.textPrimary`, etc.
extension BobColorsX on BuildContext {
  BobColors get c =>
      Theme.of(this).extension<BobColors>() ?? BobColors.dark;
}
