import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/animated_number.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/teal_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/signal_badge.dart';
import '../../services/models/analysis_models.dart';
import '../../services/models/stock_models.dart';
import '../../services/providers.dart';
import 'widgets/sparkline_chart.dart';

/// Loads a single stock detail by ticker from the mock stock service.
final FutureProviderFamily<StockDetail, String> stockDetailProvider =
    FutureProvider.family<StockDetail, String>((ref, String ticker) {
  return ref.watch(stockServiceProvider).detail(ticker);
});

/// Related links shown at the bottom of the detail screen. These are mock
/// external references so the section is not empty.
class _RelatedLink {
  const _RelatedLink(this.title, this.source);
  final String title;
  final String source;
}

/// The stock detail screen: price block, sparkline chart, teknikal, fundamental,
/// and berita sections, a Tanya BOB action, and related links.
class StockDetailScreen extends ConsumerWidget {
  const StockDetailScreen({super.key, required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StockDetail> detail =
        ref.watch(stockDetailProvider(ticker));
    return TealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: context.c.textOnCanvas,
          elevation: 0,
          title: Text(ticker),
          actions: <Widget>[
            FavoriteButton(ticker: ticker, onTeal: true),
            const SizedBox(width: 4),
          ],
        ),
        body: detail.when(
          data: (StockDetail data) => _DetailBody(detail: data),
          loading: () => Center(
            child: CircularProgressIndicator(color: context.c.accent),
          ),
          error: (Object err, StackTrace stack) => _ErrorState(ticker: ticker),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.ticker});

  final String ticker;

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
              Icons.error_outline,
              color: context.c.bearish,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Saham $ticker tidak ditemukan',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: context.c.textOnCanvas,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba pilih saham lain dari beranda.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final StockDetail detail;

  static const List<_RelatedLink> _relatedLinks = <_RelatedLink>[
    _RelatedLink('Laporan keuangan kuartalan terbaru', 'IDX'),
    _RelatedLink('Profil perusahaan dan struktur bisnis', 'RTI Business'),
    _RelatedLink('Riwayat dividen dan aksi korporasi', 'Kontan'),
  ];

  void _askBob(BuildContext context) {
    context.go(AppRoutes.aiWith(ticker: detail.ticker));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        _PriceBlock(detail: detail),
        const SizedBox(height: 20),
        _ChartCard(detail: detail),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Tanya BOB soal ${detail.ticker}',
          icon: Icons.auto_awesome,
          onPressed: () => _askBob(context),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Teknikal',
          child: Column(
            children: <Widget>[
              for (final TechnicalIndicator t in detail.teknikal)
                _MetricRow(
                  name: t.name,
                  value: t.value,
                  interpretation: t.interpretation,
                  signal: t.signal,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Fundamental',
          child: Column(
            children: <Widget>[
              for (final FundamentalMetric f in detail.fundamental)
                _MetricRow(
                  name: f.name,
                  value: f.value,
                  interpretation: f.interpretation,
                  signal: f.signal,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Berita',
          child: Column(
            children: <Widget>[
              for (final NewsHeadline n in detail.berita) _NewsRow(headline: n),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Tautan terkait',
          child: Column(
            children: <Widget>[
              for (final _RelatedLink link in _relatedLinks)
                _RelatedLinkRow(link: link),
            ],
          ),
        ),
      ],
    );
  }
}

/// Top price info block on the teal canvas.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Stock stock = detail.stock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          stock.name,
          style: text.headlineSmall?.copyWith(
            color: context.c.textOnCanvas,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${stock.ticker} . ${stock.sector}',
          style: text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            AnimatedNumber(
              value: stock.price,
              formatter: Formatters.rupiah,
              upColor: context.c.bullish,
              downColor: context.c.bearish,
              style: text.headlineMedium?.copyWith(
                    color: context.c.textOnCanvas,
                    fontWeight: FontWeight.w800,
                  ) ??
                  TextStyle(
                    color: context.c.textOnCanvas,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SignalBadge.change(
                changePercent: stock.changePercent,
                label:
                    '${Formatters.signedRupiah(stock.changeAbsolute)}  ${Formatters.percent(stock.changePercent)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            _StatChip(label: 'Tertinggi', value: Formatters.rupiah(detail.dayHigh)),
            const SizedBox(width: 8),
            _StatChip(label: 'Terendah', value: Formatters.rupiah(detail.dayLow)),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Kap. pasar',
              value: Formatters.rupiahCompact(detail.marketCap),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: context.c.bgElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          border: Border.all(color: context.c.bgSunken),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: text.bodySmall?.copyWith(color: context.c.textOnCanvas2),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                color: context.c.textOnCanvas,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chart card holding the custom-painted sparkline and the company description.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[context.c.surfaceHighlight, context.c.surface],
          stops: <double>[0.0, 0.6],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.surfaceLine),
        boxShadow: AppColors.cardShadowRich,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Pergerakan harga',
            style: text.titleSmall?.copyWith(
              color: context.c.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SparklineChart(points: detail.sparkline),
          const SizedBox(height: 12),
          Text(
            detail.description,
            style: text.bodySmall?.copyWith(
              color: context.c.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled off-white section card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[context.c.surfaceHighlight, context.c.surface],
          stops: <double>[0.0, 0.6],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.surfaceLine),
        boxShadow: AppColors.cardShadowRich,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: text.titleMedium?.copyWith(
              color: context.c.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.name,
    required this.value,
    required this.interpretation,
    required this.signal,
  });

  final String name;
  final String value;
  final String interpretation;
  final Signal signal;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.c.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              SignalBadge.signal(signal, onSurface: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            interpretation,
            style: text.bodySmall?.copyWith(
              color: context.c.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.headline});

  final NewsHeadline headline;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            headline.title,
            style: text.bodyMedium?.copyWith(
              color: context.c.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                headline.source,
                style: text.bodySmall?.copyWith(
                  color: context.c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SignalBadge.sentiment(headline.sentiment, onSurface: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedLinkRow extends StatelessWidget {
  const _RelatedLinkRow({required this.link});

  final _RelatedLink link;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.link,
            size: 18,
            color: context.c.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  link.title,
                  style: text.bodyMedium?.copyWith(
                    color: context.c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  link.source,
                  style: text.bodySmall?.copyWith(
                    color: context.c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: context.c.textSecondary,
          ),
        ],
      ),
    );
  }
}
