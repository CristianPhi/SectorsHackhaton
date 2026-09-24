import 'package:flutter/material.dart';

/// Raw color values for BOB's **light** (warm off-white, clean) mode.
///
/// Single source of truth for the light theme's colors. Mirrors the structure
/// of darkmode/dark_palette.dart token-for-token so the two modes are easy to
/// compare, and [BobColors.light] maps these onto the shared semantic contract.
///
/// Design intent agreed for light mode:
/// - Canvas is a warm off-white (not stark hospital white, not heavy cream).
/// - Cards are near-white, a touch lighter than the canvas, lifted with a soft
///   shadow.
/// - Gold stays the action color; teal is demoted to a small accent (brand
///   identity in section titles, active states, icon strokes).
/// - Green/red keep their hues but use the darker on-surface variants for
///   contrast on the light canvas.
class LightPalette {
  const LightPalette._();

  // Warm off-white canvas. A whisper of warmth, restrained.
  static const Color bgBase = Color(0xFFF5F3EE);
  static const Color bgElevated = Color(0xFFFFFFFF); // cards lift lighter
  static const Color bgSunken = Color(0xFFEDEAE1); // slightly deeper wells

  // Surfaces (cards, sheets). Near-white so they separate from the warm canvas.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0EDE5);
  static const Color surfaceLine = Color(0xFFE2DED3);

  /// Top-edge sheen for cards (barely lighter than white -> just white here).
  static const Color surfaceHighlight = Color(0xFFFFFFFF);

  // Text. On the light canvas the primary/secondary tones read as dark ink;
  // the "on-canvas" tones (which were light-on-teal in dark mode) become the
  // same dark ink so text stays legible on the warm background.
  static const Color textOnCanvas = Color(0xFF14312F); // dark ink on canvas
  static const Color textOnCanvas2 = Color(0xFF5E6E6C); // muted on canvas
  static const Color textPrimary = Color(0xFF14312F);
  static const Color textSecondary = Color(0xFF5A6B69);

  // Gold accent, for actions only (same identity as dark).
  static const Color accent = Color(0xFFCF9A2E); // slightly deeper for contrast
  static const Color accentPress = Color(0xFFB2841F);
  static const Color textOnAccent = Color(0xFF2A2000);

  /// ~18% gold wash for the active nav pill on the light bar.
  static const Color accentTint = Color(0x2ECF9A2E);

  // Data signals. On a light canvas the darker on-surface pair reads best, so
  // both the "primary" and "on-surface" tokens use the darker greens/reds.
  static const Color bullish = Color(0xFF12813C);
  static const Color bullishSoft = Color(0xFFDDEEE2); // light green wash
  static const Color bearish = Color(0xFFC6362C);
  static const Color bearishSoft = Color(0xFFF6DEDB); // light red wash
  static const Color neutral = Color(0xFF7C8B89);

  static const Color bullishOnSurface = Color(0xFF12813C);
  static const Color bearishOnSurface = Color(0xFFC6362C);
  static const Color bullishTint = Color(0x2212813C);
  static const Color bearishTint = Color(0x22C6362C);

  // Slim bottom navigation: warm-white bar with a soft top hairline.
  static const Color navSurface = Color(0xFFFFFFFF);
  static const Color navBorder = Color(0xFFE2DED3);

  // Background texture. On the light canvas the grain is mostly dark specks
  // (very low alpha) so it reads as a faint tooth rather than TV snow.
  static const Color grainLight = Color(0x08FFFFFF);
  static const Color grainDark = Color(0x0D000000); // ~5% black speck
  static const Color dot = Color(0x0A14312F); // faint teal-ink dot weave

  /// Vertical gradient stops for the light canvas: a soft warm-white top easing
  /// into a slightly deeper warm tone, so the background is never a flat slab.
  static const List<Color> canvasGradient = <Color>[
    Color(0xFFFAF8F3),
    bgBase,
    bgSunken,
  ];
}
