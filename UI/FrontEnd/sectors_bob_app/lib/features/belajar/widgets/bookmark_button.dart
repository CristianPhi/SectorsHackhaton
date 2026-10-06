import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/bob_colors.dart';
import '../learn_favorites_controller.dart';

/// A bookmark toggle that saves or unsaves a Belajar item (article or video) by
/// its id. Saving is an action, so the active state uses the gold accent; the
/// inactive state is a muted outline. Tapping plays a small scale-pop so the
/// toggle feels tactile, matching the stock FavoriteButton.
class BookmarkButton extends ConsumerStatefulWidget {
  const BookmarkButton({
    super.key,
    required this.id,
    this.onTeal = false,
    this.size = 20,
  });

  /// Stable id of the item: an article's `id` or a video's `youtubeId`.
  final String id;

  /// When true the inactive icon uses the on-canvas muted tone; otherwise the
  /// on-surface muted tone (for cards sitting on an off-white surface).
  final bool onTeal;

  final double size;

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

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
    ref.read(learnFavoritesProvider.notifier).toggle(widget.id);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool saved = ref.watch(
      learnFavoritesProvider.select((s) => s.contains(widget.id)),
    );
    final Color inactive =
        widget.onTeal ? context.c.textOnCanvas2 : context.c.textSecondary;
    return IconButton(
      onPressed: _onTap,
      visualDensity: VisualDensity.compact,
      tooltip: saved ? 'Hapus dari simpanan' : 'Simpan',
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          color: saved ? context.c.accent : inactive,
          size: widget.size,
        ),
      ),
    );
  }
}
