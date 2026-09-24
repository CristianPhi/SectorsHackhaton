import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/bob_colors.dart';
import '../../../services/models/learn_models.dart';
import 'bookmark_button.dart';

/// Opens a learning video. Real videos launch YouTube in an external app; mock
/// placeholders show a short note instead of a dead link. Shared by the big
/// [VideoCard] and the compact [VideoRow] so the behavior stays identical.
Future<void> openVideo(BuildContext context, LearnVideo video) async {
  if (!video.isReal) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ini video contoh untuk pratinjau tampilan.'),
      ),
    );
    return;
  }
  final Uri uri = Uri.parse(video.watchUrl);
  final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka video.')),
    );
  }
}

/// A learning video card: thumbnail with a play overlay, title, and channel.
/// Used in the featured (Sorotan) carousel.
///
/// Real videos open in the YouTube app (or browser) via url_launcher. Mock
/// placeholders show a "Contoh" chip and a short note when tapped instead of
/// opening a dead link, so the tab is honest about which entries are real.
class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.video, this.width});

  final LearnVideo video;

  /// Optional fixed width, used when laid out horizontally in the carousel.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Material(
      color: context.c.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: () => openVideo(context, video),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: context.c.surfaceLine),
            boxShadow: AppColors.cardShadowRich,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Thumbnail(video: video),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        color: context.c.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: context.c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            video.channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: context.c.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// A compact video row for the mixed feed: small thumbnail on the left, title
/// and channel on the right, matching the recommendation rows in the reference.
class VideoRow extends StatelessWidget {
  const VideoRow({super.key, required this.video});

  final LearnVideo video;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: context.c.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: () => openVideo(context, video),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: context.c.surfaceLine),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                child: SizedBox(
                  width: 120,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (video.isReal)
                        Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const _ThumbFallback(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return const _ThumbFallback();
                          },
                        )
                      else
                        const _ThumbFallback(),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.play_circle_outline,
                          size: 13,
                          color: context.c.accentPress,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Video  .  ${video.durationLabel}',
                          style: text.bodySmall?.copyWith(
                            color: context.c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!video.isReal) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.c.surfaceAlt,
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusPill),
                            ),
                            child: Text(
                              'Contoh',
                              style: text.bodySmall?.copyWith(
                                color: context.c.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Save toggle for videos, keyed by the YouTube id.
                        BookmarkButton(id: video.youtubeId),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: context.c.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.video});

  final LearnVideo video;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppColors.radiusCard),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (video.isReal)
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const _ThumbFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const _ThumbFallback();
                },
              )
            else
              const _ThumbFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0x55000000)],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 48,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                ),
                child: Text(
                  video.durationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (!video.isReal)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.c.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    'Contoh',
                    style: TextStyle(
                      color: context.c.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.c.bgElevated,
      child: Center(
        child: Icon(
          Icons.ondemand_video_outlined,
          color: context.c.textOnCanvas2,
          size: 34,
        ),
      ),
    );
  }
}
