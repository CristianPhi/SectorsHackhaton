import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/favorites/favorites_controller.dart';
import '../theme/bob_colors.dart';

/// A heart toggle that favorites or unfavorites a ticker.
///
/// Favoriting is an action, not a data signal, so the active heart uses the
/// gold accent rather than the green or red data colors. The inactive heart is
/// an outline in a muted tone that suits whichever canvas it sits on.
///
/// Tapping the heart plays a quick "scale-pop" (a small overshoot back to
/// rest) so the toggle feels tactile.
class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({
    super.key,
    required this.ticker,
    this.onTeal = false,
    this.size = 22,
  });

  final String ticker;

  /// When true the inactive heart uses a light tone for the teal canvas,
  /// otherwise a muted tone for off-white surfaces.
  final bool onTeal;

  final double size;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  // Pop up to 1.35x then settle back to 1.0 with a gentle overshoot.
  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ],
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    ref.read(favoritesProvider.notifier).toggle(widget.ticker);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = ref.watch(
      favoritesProvider
          .select((s) => s.contains(widget.ticker.toUpperCase())),
    );
    final BobColors c = context.c;
    final Color inactive =
        widget.onTeal ? c.textOnCanvas2 : c.textSecondary;
    return IconButton(
      onPressed: _onTap,
      visualDensity: VisualDensity.compact,
      tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? c.accent : inactive,
          size: widget.size,
        ),
      ),
    );
  }
}
