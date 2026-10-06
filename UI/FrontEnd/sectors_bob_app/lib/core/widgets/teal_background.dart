import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bob_colors.dart';

/// The immersive app canvas behind content on every BOB screen.
///
/// It is mode-aware: in dark mode it paints the teal gradient + texture; in
/// light mode it paints the warm off-white gradient + a faint grain. Either
/// way the background is never a flat slab of color. It reads its colors from
/// the active [BobColors] via `context.c`, so it flips automatically with the
/// theme.
///
/// The name is kept as `TealBackground` for continuity across the app, but it
/// now serves both modes. Wrap a screen's body (or the whole Scaffold) in this
/// and set the [Scaffold.backgroundColor] to transparent.
///
/// [seed] fixes the random grain so it is stable across rebuilds (no shimmer).
class TealBackground extends StatelessWidget {
  const TealBackground({super.key, required this.child, this.seed = 7});

  final Widget child;

  /// Fixed seed for the deterministic grain scatter.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final BobColors c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.canvasGradient,
          stops: const <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _CanvasTexturePainter(
          seed: seed,
          grainLight: c.grainLight,
          grainDark: c.grainDark,
          dot: c.dot,
        ),
        child: child,
      ),
    );
  }
}

/// Paints two stacked textures on the app canvas:
///  - a fine, deterministic grain (tiny light and dark specks) for a filmic
///    noise feel, and
///  - a faint evenly spaced dot weave for a subtle structured pattern.
///
/// All colors are passed in from the active theme so the same texture works in
/// both modes. Both layers are very low alpha and purely cosmetic (never
/// hit-tested).
class _CanvasTexturePainter extends CustomPainter {
  _CanvasTexturePainter({
    required this.seed,
    required this.grainLight,
    required this.grainDark,
    required this.dot,
  });

  final int seed;
  final Color grainLight;
  final Color grainDark;
  final Color dot;

  // Dot weave.
  static const double _spacing = 26.0;
  static const double _dotRadius = 1.1;

  // Grain: how many specks per 100x100 area, and their max size.
  static const double _grainDensity = 0.9;
  static const double _grainMaxSize = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrain(canvas, size);
    _paintDots(canvas, size);
  }

  void _paintGrain(Canvas canvas, Size size) {
    // A seeded RNG keeps the grain identical on every repaint, so it reads as a
    // baked-in texture rather than TV static.
    final math.Random rng = math.Random(seed);
    final int count =
        ((size.width * size.height) / (100 * 100) * 100 * _grainDensity)
            .round();
    final Paint light = Paint()..color = grainLight;
    final Paint dark = Paint()..color = grainDark;
    for (int i = 0; i < count; i++) {
      final double x = rng.nextDouble() * size.width;
      final double y = rng.nextDouble() * size.height;
      final double s = 0.4 + rng.nextDouble() * _grainMaxSize;
      // Mix light and dark specks so the grain reads on both the lighter top
      // and the darker bottom of the gradient.
      final Paint p = rng.nextBool() ? light : dark;
      canvas.drawCircle(Offset(x, y), s / 2, p);
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..color = dot;
    // Offset every other row by half a cell for a subtle diagonal weave.
    int row = 0;
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      final double xOffset = row.isEven ? 0 : _spacing / 2;
      for (double x = _spacing / 2 + xOffset; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, dotPaint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasTexturePainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.grainLight != grainLight ||
      oldDelegate.grainDark != grainDark ||
      oldDelegate.dot != dot;
}

/// A decorative soft radial "glow" blob, used sparingly behind hero content
/// (for example the splash logo) to add warmth to the canvas. Not interactive.
/// [color] defaults to a faint gold wash.
class GlowBlob extends StatelessWidget {
  const GlowBlob({
    super.key,
    this.size = 320,
    this.color = const Color(0x1FE9B84A),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
