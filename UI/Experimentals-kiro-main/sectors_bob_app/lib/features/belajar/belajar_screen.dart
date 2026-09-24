import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/learn_models.dart';
import '../../services/providers.dart';
import 'learn_favorites_controller.dart';
import 'widgets/article_card.dart';
import 'widgets/video_card.dart';

/// Videos for the Belajar tab.
final FutureProvider<List<LearnVideo>> learnVideosProvider =
    FutureProvider<List<LearnVideo>>((ref) {
  return ref.watch(learnServiceProvider).videos();
});

/// News articles for the Belajar feed and the in-app reader.
final FutureProvider<List<LearnArticle>> learnArticlesProvider =
    FutureProvider<List<LearnArticle>>((ref) {
  return ref.watch(learnServiceProvider).articles();
});

/// Top channels row.
final FutureProvider<List<LearnChannel>> learnChannelsProvider =
    FutureProvider<List<LearnChannel>>((ref) {
  return ref.watch(learnServiceProvider).channels();
});

/// Which content the feed shows. [favorit] scopes to saved items only.
enum _Filter { semua, video, berita, favorit }

/// The Belajar (Learn) tab. Replaces the old News tab.
///
/// Blends educational videos and market news in one feed, following the
/// reference news-app layout: a search field, a Top Kanal channel row, a
/// featured video carousel (Sorotan), filter chips (Semua / Video / Berita),
/// and a mixed vertical feed of compact video and article rows. Videos open on
/// YouTube; articles open an in-app reader. All content is backed by the mock
/// [LearnService].
class BelajarScreen extends ConsumerStatefulWidget {
  const BelajarScreen({super.key});

  @override
  ConsumerState<BelajarScreen> createState() => _BelajarScreenState();
}

class _BelajarScreenState extends ConsumerState<BelajarScreen> {
  final TextEditingController _search = TextEditingController();
  _Filter _filter = _Filter.semua;
  String _query = '';

  /// When set, the feed is scoped to this channel or source name.
  String? _channel;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesQuery(String haystack) =>
      _query.isEmpty || haystack.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<List<LearnVideo>> videos = ref.watch(learnVideosProvider);
    final AsyncValue<List<LearnArticle>> articles =
        ref.watch(learnArticlesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TealBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Belajar',
                      style: text.headlineSmall?.copyWith(
                        color: context.c.textOnCanvas,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Video edukasi dan berita pasar untuk investor.',
                      style: text.bodyMedium
                          ?.copyWith(color: context.c.textOnCanvas2),
                    ),
                    const SizedBox(height: 16),
                    _SearchField(
                      controller: _search,
                      onChanged: (String v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildChannels(),
            if (_filter == _Filter.semua || _filter == _Filter.video)
              _buildFeatured(videos),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _FilterChips(
                  active: _filter,
                  onChanged: (_Filter f) => setState(() => _filter = f),
                ),
              ),
            ),
            _buildFeed(videos, articles),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannels() {
    final AsyncValue<List<LearnChannel>> channels =
        ref.watch(learnChannelsProvider);
    return SliverToBoxAdapter(
      child: channels.maybeWhen(
        data: (List<LearnChannel> list) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _SectionHeader(title: 'Top Kanal'),
              ),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final LearnChannel c = list[i];
                    final bool active = _channel == c.name;
                    return _ChannelChip(
                      channel: c,
                      active: active,
                      onTap: () => setState(() {
                        _channel = active ? null : c.name;
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFeatured(AsyncValue<List<LearnVideo>> videos) {
    return SliverToBoxAdapter(
      child: videos.maybeWhen(
        data: (List<LearnVideo> all) {
          final List<LearnVideo> list = all
              .where((LearnVideo v) =>
                  (_channel == null || v.channel == _channel) &&
                  _matchesQuery('${v.title} ${v.channel}'))
              .toList();
          if (list.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _SectionHeader(title: 'Sorotan'),
                ),
                SizedBox(
                  // 280-wide cards render a 16:9 thumbnail (~158px) plus the
                  // title/channel block (~90px), so the intrinsic card height is
                  // ~250px. The old 220px box clipped that by ~30px; 252 gives
                  // the content room without a visible gap.
                  height: 252,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) =>
                        VideoCard(video: list[i], width: 280),
                  ),
                ),
              ],
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFeed(
    AsyncValue<List<LearnVideo>> videos,
    AsyncValue<List<LearnArticle>> articles,
  ) {
    // Both sources must be ready to compose the mixed feed.
    if (videos.isLoading || articles.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: context.c.accent),
          ),
        ),
      );
    }
    if (videos.hasError || articles.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Text(
              'Gagal memuat konten. Coba lagi nanti.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.c.bearish),
            ),
          ),
        ),
      );
    }

    final Set<String> saved = ref.watch(learnFavoritesProvider);
    final List<_FeedItem> items = _composeFeed(
      videos.value ?? const <LearnVideo>[],
      articles.value ?? const <LearnArticle>[],
      saved,
    );

    if (items.isEmpty) {
      // The Favorit tab gets a friendlier, dedicated empty state.
      if (_filter == _Filter.favorit) {
        return const SliverToBoxAdapter(child: _SavedEmpty());
      }
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Text(
              'Tidak ada konten yang cocok.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.c.textOnCanvas2),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final _FeedItem item = items[i];
            final Widget child = item.video != null
                ? VideoRow(video: item.video!)
                : ArticleCard(
                    article: item.article!,
                    onTap: () => context.push(
                      AppRoutes.article(item.article!.id),
                    ),
                  );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  /// Builds the interleaved feed honoring the active filter, channel, query, and
  /// (for the Favorit filter) the set of [saved] item ids.
  List<_FeedItem> _composeFeed(
    List<LearnVideo> videos,
    List<LearnArticle> articles,
    Set<String> saved,
  ) {
    final List<LearnVideo> vids = videos
        .where((LearnVideo v) =>
            (_channel == null || v.channel == _channel) &&
            _matchesQuery('${v.title} ${v.channel}'))
        .toList();
    final List<LearnArticle> arts = articles
        .where((LearnArticle a) =>
            (_channel == null || a.source == _channel) &&
            _matchesQuery('${a.title} ${a.source}'))
        .toList();

    List<_FeedItem> interleave() {
      // Interleave articles and videos so both are visible without one block
      // dominating. Articles lead since they read as "latest news".
      final List<_FeedItem> out = <_FeedItem>[];
      final int max = arts.length > vids.length ? arts.length : vids.length;
      for (int i = 0; i < max; i++) {
        if (i < arts.length) {
          out.add(_FeedItem.ofArticle(arts[i]));
        }
        if (i < vids.length) {
          out.add(_FeedItem.ofVideo(vids[i]));
        }
      }
      return out;
    }

    switch (_filter) {
      case _Filter.video:
        return vids.map(_FeedItem.ofVideo).toList();
      case _Filter.berita:
        return arts.map(_FeedItem.ofArticle).toList();
      case _Filter.semua:
        return interleave();
      case _Filter.favorit:
        // Only saved items, keeping the interleaved order.
        return interleave()
            .where((_FeedItem item) => saved.contains(
                  item.article?.id ?? item.video?.youtubeId ?? '',
                ))
            .toList();
    }
  }
}

/// Friendly empty state for the Favorit filter when nothing is saved yet.
class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: context.c.bgElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(color: context.c.bgSunken),
        ),
        child: Column(
          children: <Widget>[
            Icon(Icons.bookmark_border, color: context.c.accent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Belum ada yang disimpan',
              style: text.titleMedium?.copyWith(
                color: context.c.textOnCanvas,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk ikon bookmark pada video atau berita untuk menyimpannya '
              'di sini.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single feed entry: exactly one of [video] or [article] is non-null.
class _FeedItem {
  const _FeedItem._({this.video, this.article});

  factory _FeedItem.ofVideo(LearnVideo v) => _FeedItem._(video: v);
  factory _FeedItem.ofArticle(LearnArticle a) => _FeedItem._(article: a);

  final LearnVideo? video;
  final LearnArticle? article;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.c.textOnCanvas,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        border: Border.all(color: context.c.surfaceLine),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search, color: context.c.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: context.c.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari video atau berita',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.channel,
    required this.active,
    required this.onTap,
  });

  final LearnChannel channel;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? context.c.accent : context.c.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? context.c.accent : context.c.surfaceLine,
                  width: 2,
                ),
              ),
              child: Text(
                channel.initials,
                style: TextStyle(
                  color: active
                      ? context.c.textOnAccent
                      : context.c.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.c.textOnCanvas2,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final _Filter active;
  final ValueChanged<_Filter> onChanged;

  static const List<(_Filter, String)> _options = <(_Filter, String)>[
    (_Filter.semua, 'Semua'),
    (_Filter.video, 'Video'),
    (_Filter.berita, 'Berita'),
    (_Filter.favorit, 'Favorit'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map(((_Filter, String) o) {
        final bool selected = active == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? context.c.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              border: Border.all(
                color: selected ? context.c.accent : context.c.textOnCanvas2,
              ),
            ),
            child: Text(
              o.$2,
              style: TextStyle(
                color:
                    selected ? context.c.textOnAccent : context.c.textOnCanvas2,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
