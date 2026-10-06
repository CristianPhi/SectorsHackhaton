import 'package:flutter/material.dart';

/// A one-shot entrance animation that fades a child in while sliding it up a
/// short distance. Used to give list items (stock cards, chat bubbles) a
/// staggered "settle into place" feel as they appear.
///
/// Pass an [index] and the widget staggers its own start by [stagger] * index,
/// capped by [maxStaggerItems] so a long list never waits too long for its
/// tail to appear. The animation plays once when the widget first mounts; it
/// does not replay on rebuilds, so scrolling a list back into view is instant.
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
    this.stagger = const Duration(milliseconds: 60),
    this.maxStaggerItems = 8,
    this.offsetY = 18,
    this.curve = Curves.easeOutCubic,
  });

  /// The content to reveal.
  final Widget child;

  /// Position of this item in its list. Later items start later.
  final int index;

  /// How long each item's fade + slide runs.
  final Duration duration;

  /// Delay added per [index] before an item begins animating.
  final Duration stagger;

  /// Items beyond this position share the same (maximum) delay so a long list
  /// does not take forever to finish revealing.
  final int maxStaggerItems;

  /// How far, in logical pixels, the child slides up as it fades in.
  final double offsetY;

  /// Easing for both the fade and the slide.
  final Curve curve;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    final int effectiveIndex =
        widget.index.clamp(0, widget.maxStaggerItems);
    final Duration delay = widget.stagger * effectiveIndex;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curved.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
