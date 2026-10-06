import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'bob_colors.dart';

/// Builds BOB's light and dark themes.
///
/// Both modes share one layout; only the palette differs. Each [ThemeData]
/// carries a [BobColors] extension (the semantic tokens screens read via
/// `context.c`) plus Material component themes wired from the same tokens so
/// built-in widgets (buttons, inputs, dividers, app bar) flip automatically.
///
/// The gold accent is wired into button slots only. Data-signal colors (green
/// and red) are intentionally kept out of the button themes so they can only be
/// applied deliberately on data, never on interactive controls.
class AppTheme {
  const AppTheme._();

  /// The dark, teal-first theme (BOB's original look).
  static ThemeData dark() => _build(BobColors.dark);

  /// The light, warm off-white theme.
  static ThemeData light() => _build(BobColors.light);

  static ThemeData _build(BobColors c) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: c.brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: c.textOnAccent,
      surface: c.surface,
      onSurface: c.textPrimary,
    );

    final TextTheme baseText = GoogleFonts.plusJakartaSansTextTheme(
      c.isDark ? ThemeData(brightness: Brightness.dark).textTheme : null,
    );
    final TextTheme textTheme = baseText.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    final RoundedRectangleBorder pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgBase,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(color: c.surfaceLine),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: c.surfaceLine,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.textOnAccent,
          disabledBackgroundColor: c.surfaceAlt,
          disabledForegroundColor: c.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: pillShape,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return c.accentPress;
            }
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.textOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: pillShape,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return c.accentPress;
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.surfaceLine),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          shape: pillShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textPrimary,
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: BorderSide(color: c.surfaceLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          borderSide: BorderSide(color: c.surfaceLine),
        ),
      ),
    );
  }
}
