import 'package:flutter/material.dart';

/// Raw color values for BOB's **dark** (teal-first, immersive) mode.
///
/// This file is the single source of truth for every color the dark theme
/// uses. It holds only values, no logic; [BobColors.dark] in bob_colors.dart
/// maps these onto the shared semantic token contract. Keep the light mode's
/// equivalents in lightmode/light_palette.dart so the two modes stay easy to
/// compare side by side.
///
/// Palette rules (unchanged across modes):
/// - Gold is for ACTIONS only (buttons, primary calls to action).
/// - Green and red are DATA signals only, never on buttons.
class DarkPalette {
  const DarkPalette._();

  // Teal canvas.
  static const Color bgBase = Color(0xFF0B2E2C);
  static const Color bgElevated = Color(0xFF0F3B38);
  static const Color bgSunken = Color(0xFF082523);

  // Off-white surfaces (cards sit on the teal canvas).
  static const Color surface = Color(0xFFF4F1E9);
  static const Color surfaceAlt = Color(0xFFE8E4D8);
  static const Color surfaceLine = Color(0xFFD6D1C4);

  /// A lighter off-white for the top-edge sheen on cards.
  static const Color surfaceHighlight = Color(0xFFFBF9F3);

  // Text.
  static const Color textOnCanvas = Color(0xFFF4F1E9); // light text on teal
  static const Color textOnCanvas2 = Color(0xFFA9C4C0); // muted on teal
  static const Color textPrimary = Color(0xFF14312F); // dark text on surface
  static const Color textSecondary = Color(0xFF5A6B69); // muted on surface

  // Gold accent, for actions only.
  static const Color accent = Color(0xFFE9B84A);
  static const Color accentPress = Color(0xFFC99A2F);
  static const Color textOnAccent = Color(0xFF2A2000);

  /// ~16% gold wash, used for the active nav pill and gold splashes.
  static const Color accentTint = Color(0x29E9B84A);

  // Data signals (bright-on-dark pair for the teal canvas + soft backgrounds).
  static const Color bullish = Color(0xFF22C55E);
  static const Color bullishSoft = Color(0xFF16351F);
  static const Color bearish = Color(0xFFFF5A4D);
  static const Color bearishSoft = Color(0xFF3A1614);
  static const Color neutral = Color(0xFF9AA8A6);

  // Darker data colors + tints for use on off-white surfaces.
  static const Color bullishOnSurface = Color(0xFF12813C);
  static const Color bearishOnSurface = Color(0xFFC6362C);
  static const Color bullishTint = Color(0x2422C55E);
  static const Color bearishTint = Color(0x24FF5A4D);

  // Slim bottom navigation.
  static const Color navSurface = Color(0xFF0E3835);
  static const Color navBorder = Color(0xFF10403C);

  // Background texture (noise/grain and dot weave) tuned for the dark canvas.
  static const Color grainLight = Color(0x0AFFFFFF); // ~4% white speck
  static const Color grainDark = Color(0x0A000000); // ~4% black speck
  static const Color dot = Color(0x0FFFFFFF); // ~6% white dot weave

  /// Vertical gradient stops for the immersive canvas.
  static const List<Color> canvasGradient = <Color>[
    bgElevated,
    bgBase,
    bgSunken,
  ];
}
