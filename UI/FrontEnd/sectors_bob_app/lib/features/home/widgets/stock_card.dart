import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
// AppColors and AppSpacing both live in app_colors.dart.
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/bob_colors.dart';
import '../../../core/widgets/animated_number.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/signal_badge.dart';
import '../../../services/models/stock_models.dart';

/// A tappable stock row used across Home sections.
///
/// Shows ticker, company name, Rupiah price, and a change badge in data colors.
/// A quick Tanya BOB affordance opens the chat seeded with this ticker. The row
/// itself opens the stock detail.
class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.stock,
    required this.onTap,
    this.onAskBob,
  });

  final Stock stock;
  final VoidCallback onTap;
  final VoidCallback? onAskBob;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            // A gentle top-to-bottom sheen: a lighter off-white at the top edge
            // easing into the base surface gives the card a subtle sense of
            // light from above instead of a flat fill.
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
          child: Row(
            children: <Widget>[
              _TickerAvatar(ticker: stock.ticker),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stock.ticker,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  AnimatedNumber(
                    value: stock.price,
                    formatter: Formatters.rupiah,
                    upColor: context.c.bullish,
                    downColor: context.c.bearish,
                    style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  SignalBadge.change(
                    changePercent: stock.changePercent,
                    label: Formatters.percent(stock.changePercent),
                    onSurface: true,
                  ),
                ],
              ),
              const SizedBox(width: 2),
              FavoriteButton(ticker: stock.ticker, size: 20),
              if (onAskBob != null)
                IconButton(
                  onPressed: onAskBob,
                  tooltip: 'Tanya BOB soal ${stock.ticker}',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.auto_awesome_outlined,
                    color: context.c.accentPress,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small rounded square holding the first letters of the ticker.
class _TickerAvatar extends StatelessWidget {
  const _TickerAvatar({required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.c.bgBase,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      ),
      child: Text(
        ticker.length >= 2 ? ticker.substring(0, 2) : ticker,
        style: TextStyle(
          color: context.c.textOnCanvas,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
