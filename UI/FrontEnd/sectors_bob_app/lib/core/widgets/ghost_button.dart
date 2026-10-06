import 'package:flutter/material.dart';

import '../theme/bob_colors.dart';

/// A low-emphasis button for the app canvas.
///
/// Transparent fill with a hairline border and canvas text, so it reads clearly
/// on the immersive canvas (splash, onboarding) without competing with the gold
/// primary action. It carries no data-signal color and adapts to light/dark.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// When true the button stretches to fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final BobColors c = context.c;
    final Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textOnCanvas,
        side: BorderSide(color: c.textOnCanvas2),
        backgroundColor: Colors.transparent,
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
