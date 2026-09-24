import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/stock_models.dart';
import '../../services/models/user_models.dart';
import '../../services/providers.dart';
import 'home_providers.dart';
import 'widgets/stock_card.dart';

/// Suggested questions shown in the Tanya BOB card. Natural, everyday phrasing.
const List<String> _suggestedQuestions = <String>[
  'Bagaimana BBCA hari ini?',
  'Bandingkan BBRI dan BMRI',
  'Saham bank mana yang menarik?',
];

/// The Home (Beranda) hero screen.
///
/// Teal canvas with a top bar (a stock search field with the profile avatar to
/// its right), a Tanya BOB card that opens the chat, a Favorit/Discover toggle,
/// and the matching stock lists sourced from the mock stock service. BOB is an
/// information and analysis tool, not a broker or portfolio tracker, so nothing
/// here implies holdings or gains that are not real.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _ask = TextEditingController();

  /// 0 = Favorit, 1 = Discover.
  int _tab = 1;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _openChat({String? seed, String? ticker}) {
    context.go(AppRoutes.aiWith(seed: seed, ticker: ticker));
  }

  void _submitAsk() {
    final String text = _ask.text.trim();
    _openChat(seed: text.isEmpty ? null : text);
  }

  void _openStock(String ticker) => context.push(AppRoutes.stock(ticker));

  /// Pull-to-refresh: invalidate the stock providers so the visible lists
  /// re-fetch. Re-fetching gives each list a fresh set of StockCards, which
  /// replays their staggered entrance animation. A short delay keeps the
  /// refresh spinner visible long enough to feel intentional on the mock.
  Future<void> _refresh() async {
    ref.invalidate(localStocksProvider);
    ref.invalidate(recentlySearchedProvider);
    ref.invalidate(favoriteStocksProvider);
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TealBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: context.c.accent,
            backgroundColor: context.c.surface,
            onRefresh: _refresh,
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  _SegmentToggle(
                    index: _tab,
                    labels: const <String>['Favorit', 'Discover'],
                    onChanged: (int i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 20),
                  if (_tab == 0)
                    _FavoritesTab(
                      onOpenStock: _openStock,
                      onAskBob: (String t) => _openChat(ticker: t),
                    )
                  else
                    _DiscoverTab(
                      onOpenStock: _openStock,
                      onAskBob: (String t) => _openChat(ticker: t),
                    ),
                ]),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppUser? user = ref.watch(authStateProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _SearchBar(
                  onTap: () => context.push(AppRoutes.search),
                ),
              ),
              const SizedBox(width: 12),
              _ProfileAvatar(
                user: user,
                onTap: () => context.push(AppRoutes.profile),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Halo, ${user?.displayName.split(' ').first ?? 'investor'}',
            style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
          ),
          const SizedBox(height: 2),
          Text(
            'Mau tanya saham apa hari ini?',
            style: text.headlineSmall?.copyWith(
              color: context.c.textOnCanvas,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _AskBobCard(
            controller: _ask,
            onSubmit: _submitAsk,
            onSuggestion: (String q) => _openChat(seed: q),
          ),
        ],
      ),
    );
  }
}

/// The Discover tab: local stocks and recent history.
class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({required this.onOpenStock, required this.onAskBob});

  final ValueChanged<String> onOpenStock;
  final ValueChanged<String> onAskBob;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _StockSection(
          title: 'Saham Lokal',
          provider: localStocksProvider,
          onOpenStock: onOpenStock,
          onAskBob: onAskBob,
        ),
        const SizedBox(height: 24),
        _StockSection(
          title: 'Riwayat Terakhir',
          provider: recentlySearchedProvider,
          onOpenStock: onOpenStock,
          onAskBob: onAskBob,
        ),
      ],
    );
  }
}

/// The Favorit tab: favorited stocks with a friendly empty state.
class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({required this.onOpenStock, required this.onAskBob});

  final ValueChanged<String> onOpenStock;
  final ValueChanged<String> onAskBob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Stock>> favorites =
        ref.watch(favoriteStocksProvider);
    final TextTheme text = Theme.of(context).textTheme;
    return favorites.when(
      data: (List<Stock> list) {
        if (list.isEmpty) {
          return const _FavoritesEmpty();
        }
        return Column(
          children: <Widget>[
            for (int i = 0; i < list.length; i++) ...<Widget>[
              AnimatedEntrance(
                index: i,
                child: StockCard(
                  stock: list[i],
                  onTap: () => onOpenStock(list[i].ticker),
                  onAskBob: () => onAskBob(list[i].ticker),
                ),
              ),
              if (i != list.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: context.c.accent)),
      ),
      error: (Object err, StackTrace stack) => Text(
        'Gagal memuat favorit. Coba lagi nanti.',
        style: text.bodyMedium?.copyWith(color: context.c.bearish),
      ),
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: context.c.bgElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.bgSunken),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.favorite_border,
              color: context.c.accent, size: 36),
          const SizedBox(height: 12),
          Text(
            'Belum ada favorit',
            style: text.titleMedium?.copyWith(
              color: context.c.textOnCanvas,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk ikon hati pada saham untuk menyimpannya di sini.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
          ),
        ],
      ),
    );
  }
}

/// The read-only search bar on Home. Tapping it opens the full search screen.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
            border: Border.all(color: context.c.surfaceLine),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.search,
                  color: context.c.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cari saham',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.c.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The circular profile avatar to the right of the search bar.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.onTap});

  final AppUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(user?.displayName ?? 'Investor');
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 46,
        width: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.c.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: context.c.textOnAccent,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'IN';
    }
    if (parts.length == 1) {
      final String p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

/// The Tanya BOB card: an ask field plus suggestion chips that open the chat.
class _AskBobCard extends StatelessWidget {
  const _AskBobCard({
    required this.controller,
    required this.onSubmit,
    required this.onSuggestion,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.bgElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.bgSunken),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome,
                  color: context.c.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tanya BOB',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.c.textOnCanvas,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AskBar(controller: controller, onSubmit: onSubmit),
          const SizedBox(height: 12),
          _SuggestedQuestions(onSelected: onSuggestion),
        ],
      ),
    );
  }
}

/// The ask-BOB input pill. Submitting opens the chat with the typed prompt.
class _AskBar extends StatelessWidget {
  const _AskBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        border: Border.all(color: context.c.surfaceLine),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(color: context.c.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tanya BOB is this bullish or bearish',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: context.c.accent,
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                onTap: onSubmit,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    Icons.arrow_forward,
                    color: context.c.textOnAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold-outline suggestion chips shown below the ask bar.
class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedQuestions.map((String q) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          onTap: () => onSelected(q),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              border: Border.all(color: context.c.accent),
            ),
            child: Text(
              q,
              style: TextStyle(
                color: context.c.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// The Favorit/Discover pill toggle.
class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.bgElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        border: Border.all(color: context.c.bgSunken),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? context.c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: index == i
                          ? context.c.textOnAccent
                          : context.c.textOnCanvas2,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A titled section that renders an async list of stocks with loading and error
/// states.
class _StockSection extends ConsumerWidget {
  const _StockSection({
    required this.title,
    required this.provider,
    required this.onOpenStock,
    required this.onAskBob,
  });

  final String title;
  final FutureProvider<List<Stock>> provider;
  final ValueChanged<String> onOpenStock;
  final ValueChanged<String> onAskBob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Stock>> stocks = ref.watch(provider);
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: text.titleMedium?.copyWith(
            color: context.c.textOnCanvas,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        stocks.when(
          data: (List<Stock> list) {
            if (list.isEmpty) {
              return Text(
                'Belum ada data.',
                style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
              );
            }
            return Column(
              children: <Widget>[
                for (int i = 0; i < list.length; i++) ...<Widget>[
                  AnimatedEntrance(
                    index: i,
                    child: StockCard(
                      stock: list[i],
                      onTap: () => onOpenStock(list[i].ticker),
                      onAskBob: () => onAskBob(list[i].ticker),
                    ),
                  ),
                  if (i != list.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: context.c.accent),
            ),
          ),
          error: (Object err, StackTrace stack) => Text(
            'Gagal memuat data. Coba lagi nanti.',
            style: text.bodyMedium?.copyWith(color: context.c.bearish),
          ),
        ),
      ],
    );
  }
}
