import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/bob_colors.dart';

/// A lightweight line chart for the stock detail price history.
///
/// It draws the [points] as a smooth polyline with a soft gradient fill. The
/// line color follows the net direction of the series: bullish green when the
/// last point is above the first, bearish red otherwise. Colors here are data
/// only, never actions.
///
/// When the chart first appears it animates the line "drawing on" from left to
/// right, with the gradient fill and the latest-point dot fading in as the
/// draw completes. The animation plays once per mount; if [points] change the
/// chart redraws to the new series without replaying the draw-on.
class SparklineChart extends StatefulWidget {
  const SparklineChart({super.key, required this.points, this.height = 140});

  final List<double> points;
  final double height;

  @override
  State<SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<SparklineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<double> points = widget.points;
    final bool isUp = points.isNotEmpty && points.last >= points.first;
    final Color lineColor = isUp ? context.c.bullish : context.c.bearish;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (BuildContext context, _) {
          return CustomPaint(
            painter: _SparklinePainter(
              points: points,
              lineColor: lineColor,
              progress: _progress.value,
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.progress,
  });

  final List<double> points;
  final Color lineColor;

  /// Fraction of the line drawn so far, 0..1.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || progress <= 0) {
      return;
    }

    double min = points.first;
    double max = points.first;
    for (final double p in points) {
      if (p < min) min = p;
      if (p > max) max = p;
    }
    final double range = (max - min).abs() < 0.0001 ? 1 : (max - min);

    const double topPad = 8;
    final double usableHeight = size.height - topPad * 2;
    final double stepX = size.width / (points.length - 1);

    Offset pointAt(int i) {
      final double x = stepX * i;
      final double normalized = (points[i] - min) / range;
      final double y = topPad + (1 - normalized) * usableHeight;
      return Offset(x, y);
    }

    // Build the full line path, then extract only the leading [progress]
    // fraction so the line appears to draw on from left to right.
    final Path fullPath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < points.length; i++) {
      fullPath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

  final metrics = fullPath.computeMetrics();
    final Path drawnPath = Path();
    double drawnLength = 0;
    double totalLength = 0;
    Offset lastDrawnPoint = pointAt(0);
    for (final metric in metrics) {
      totalLength += metric.length;
    }
    final double target = totalLength * progress;
    for (final metric in fullPath.computeMetrics()) {
      final double remaining = target - drawnLength;
      if (remaining <= 0) {
        break;
      }
      final double take = remaining < metric.length ? remaining : metric.length;
      drawnPath.addPath(metric.extractPath(0, take), Offset.zero);
      final tan = metric.getTangentForOffset(take);
      if (tan != null) {
        lastDrawnPoint = tan.position;
      }
      drawnLength += metric.length;
    }

    // Soft gradient fill under the drawn portion. It fades in with progress so
    // it does not pop before the line has traced across.
    final Path fillPath = Path.from(drawnPath)
      ..lineTo(lastDrawnPoint.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    final double fillOpacity = progress;
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // withOpacity is used here (not withValues) on purpose: the pubspec SDK
        // floor is >=3.3.0, and withValues(alpha:) only exists on newer stable
        // SDKs. Newer SDKs may show a deprecation notice for withOpacity; if the
        // floor is bumped past 3.27, switch these calls to withValues(alpha:).
        // See the minimum SDK note in README.md.
        colors: <Color>[
          lineColor.withOpacity(0.24 * fillOpacity),
          lineColor.withOpacity(0.02 * fillOpacity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(drawnPath, linePaint);

    // The latest-point dot fades in over the final stretch of the draw so it
    // lands as the line reaches the right edge.
    final double dotOpacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    if (dotOpacity > 0) {
      final Offset last = pointAt(points.length - 1);
      canvas.drawCircle(
        last,
        3.5,
        Paint()..color = lineColor.withOpacity(dotOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.progress != progress;
  }
}
