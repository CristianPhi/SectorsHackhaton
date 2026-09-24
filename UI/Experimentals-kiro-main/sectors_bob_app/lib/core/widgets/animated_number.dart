import 'package:flutter/material.dart';

/// A numeric text widget that animates ("counts up") between values whenever
/// [value] changes, and briefly pulses its color on a change so the update is
/// noticeable. Perfect for stock prices and percent changes.
///
/// The [formatter] converts the interpolated double into display text (for
/// example a Rupiah or percent formatter). When the value moves up the pulse
/// uses [upColor]; when it moves down, [downColor]. On first build there is no
/// pulse, only the resting [style] color.
class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.upColor = const Color(0xFF1FA97A),
    this.downColor = const Color(0xFFE5484D),
    this.countDuration = const Duration(milliseconds: 650),
    this.pulseDuration = const Duration(milliseconds: 900),
    this.textAlign,
  });

  /// The target numeric value to display and animate toward.
  final double value;

  /// Converts the current interpolated value into display text.
  final String Function(double value) formatter;

  /// The resting text style (its color is used when not pulsing).
  final TextStyle style;

  /// Pulse color when the value increased.
  final Color upColor;

  /// Pulse color when the value decreased.
  final Color downColor;

  /// How long the count-up interpolation runs.
  final Duration countDuration;

  /// How long the color pulse takes to fade back to the resting color.
  final Duration pulseDuration;

  final TextAlign? textAlign;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late double _previous = widget.value;
  late double _current = widget.value;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: widget.pulseDuration,
    value: 1.0, // start fully "settled" (no pulse on first build)
  );

  Color? _pulseColor;

  @override
  void didUpdateWidget(covariant AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previous = _current;
      _current = widget.value;
      _pulseColor =
          widget.value >= oldWidget.value ? widget.upColor : widget.downColor;
      _pulse
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color restColor = widget.style.color ?? const Color(0xFF000000);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, _) {
        final Color color = (_pulseColor == null)
            ? restColor
            : Color.lerp(_pulseColor, restColor, _pulse.value) ?? restColor;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _previous, end: _current),
          duration: widget.countDuration,
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double animated, _) {
            return Text(
              widget.formatter(animated),
              textAlign: widget.textAlign,
              style: widget.style.copyWith(color: color),
            );
          },
        );
      },
    );
  }
}
