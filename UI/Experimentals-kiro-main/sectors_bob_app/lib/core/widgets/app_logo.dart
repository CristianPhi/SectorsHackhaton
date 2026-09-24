import 'package:flutter/material.dart';

import '../theme/bob_colors.dart';

/// The BOB logo widget that renders the brand logo image asset.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 44,
    this.showSubtitle = true,
    this.showWordmark = true,
    this.onTeal = true,
    this.assetPath = 'assets/images/logo.png',
  });

  /// Height of the logo PNG image.
  final double size;

  /// When true the subtitle ('Analis saham AI') is shown below the logo image.
  final bool showSubtitle;

  /// Backwards-compatible alias for [showSubtitle].
  final bool showWordmark;

  /// When true text colors are tuned for the teal canvas, otherwise for the
  /// off-white surface.
  final bool onTeal;

  /// Asset path for the logo image.
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final BobColors c = context.c;
    final bool displaySubtitle = showSubtitle && showWordmark;
    final Color subColor = onTeal ? c.textOnCanvas2 : c.textSecondary;

    final Widget logoImage = Image.asset(
      assetPath,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        return Icon(
          Icons.interests_rounded,
          size: size,
          color: onTeal ? c.textOnCanvas : c.textPrimary,
        );
      },
    );

    if (!displaySubtitle) {
      return logoImage;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        logoImage,
        // The logo asset is tightly cropped (no baked-in transparent padding),
        // so the subtitle needs a real, deliberate gap under the mark rather
        // than relying on empty pixels inside the image.
        SizedBox(height: (size * 0.14).clamp(8.0, 22.0)),
        Text(
          'Analis saham AI',
          style: TextStyle(
            color: subColor,
            fontSize: (size * 0.14).clamp(12.0, 18.0),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
