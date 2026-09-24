import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/stock_models.dart';
import '../../services/providers.dart';
import '../home/widgets/stock_card.dart';

/// Live stock search results for the current query.
final AutoDisposeFutureProviderFamily<List<Stock>, String>
    searchResultsProvider =
    FutureProvider.autoDispose.family<List<Stock>, String>((ref, String query) {
  return ref.watch(stockServiceProvider).search(query);
});

/// The full-screen stock search, pushed from the Home search bar.
///
/// A search field with live filtering by ticker or company name. Tapping a
/// result opens its stock detail. An empty query lists every known stock so the
/// screen is useful before typing.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  String _current = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _openStock(String ticker) => context.push(AppRoutes.stock(ticker));

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Stock>> results =
        ref.watch(searchResultsProvider(_current));
    return TealBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.c.textOnCanvas,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _SearchField(
            controller: _query,
            onChanged: (String v) => setState(() => _current = v),
            onClear: () => setState(() {
              _query.clear();
              _current = '';
            }),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: results.when(
          data: (List<Stock> list) {
            if (list.isEmpty) {
              return _EmptyResults(query: _current);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => AnimatedEntrance(
                index: i,
                child: StockCard(
                  stock: list[i],
                  onTap: () => _openStock(list[i].ticker),
                ),
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: context.c.accent),
          ),
          error: (Object err, StackTrace stack) => Center(
            child: Text(
              'Gagal mencari. Coba lagi.',
              style: TextStyle(color: context.c.bearish),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6),
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
              autofocus: true,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: context.c.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari saham, misalnya BBCA',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close,
                color: context.c.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_off,
              color: context.c.textOnCanvas2,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil untuk "$query"',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: context.c.textOnCanvas,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci lain atau kode saham.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
            ),
          ],
        ),
      ),
    );
  }
}
