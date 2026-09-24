import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/settings_providers.dart';

/// Cross-fades the whole app when the theme mode flips.
///
/// When [isDarkModeProvider] changes, this captures a bitmap snapshot of the
/// previous (old-theme) frame and paints it on top of the app, then fades that
/// snapshot out over [duration]. The real app underneath is already showing the
/// new theme, so the effect is a smooth cross-fade of *everything* — canvas
/// gradient, grain, cards, and text — with no per-screen work.
///
/// Wrap the router content with this via [MaterialApp.router.builder].
class ThemeSwitchFade extends ConsumerStatefulWidget {
  const ThemeSwitchFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget child;
  final Duration duration;

  @override
  ConsumerState<ThemeSwitchFade> createState() => _ThemeSwitchFadeState();
}

class _ThemeSwitchFadeState extends ConsumerState<ThemeSwitchFade>
    with SingleTickerProviderStateMixin {
  /// Boundary key used to capture the current frame as an image.
  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// The captured old-theme frame, shown on top and faded out. Null when idle.
  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        // Drop the snapshot once the fade finishes so we stop compositing it.
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  /// Grabs the current frame from the RepaintBoundary as a raster image.
  Future<void> _capture() async {
    final RenderObject? obj = _boundaryKey.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) {
      return;
    }
    try {
      // toImageSync keeps the capture on the same frame as the pending theme
      // change, so the snapshot is the old look, not the new one.
      final ui.Image image = obj.toImageSync();
      _snapshot?.dispose();
      _snapshot = image;
      _controller
        ..reset()
        ..forward();
    } catch (_) {
      // If capture fails (e.g. first frame not painted yet) just skip the fade;
      // the theme still changes, only without the animation.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fire a capture the instant the mode flips. The listener runs during
    // build; scheduling the capture in a post-frame callback would grab the new
    // theme, so we capture synchronously here from the *current* (old) frame.
    ref.listen<bool>(isDarkModeProvider, (bool? previous, bool next) {
      if (previous != null && previous != next) {
        _capture();
      }
    });

    return Stack(
      children: <Widget>[
        RepaintBoundary(
          key: _boundaryKey,
          child: widget.child,
        ),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, _) {
                  return Opacity(
                    opacity: 1.0 - _controller.value,
                    child: RawImage(
                      image: _snapshot,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
