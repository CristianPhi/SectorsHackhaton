import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/bob_colors.dart';
import '../../../core/widgets/signal_badge.dart';
import '../../../services/models/analysis_models.dart';

/// Renders a [StockAnalysis] as a clean off-white card.
///
/// Progressive disclosure: the plain-language summary shows first, and the
/// TEKNIKAL, FUNDAMENTAL, and BERITA detail sections sit inside expandable
/// panels. The DYOR disclaimer is pinned at the bottom with a dashed top border
/// and has no dismiss control.
class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      // A Material sits between the decorated container and the inner
      // ExpansionTiles so their ListTile ink and background paint on a real
      // Material ancestor. Without it, newer Flutter asserts that the
      // ListTile's effects would be hidden by this container's own color.
      child: Material(
        color: context.c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(color: context.c.surfaceLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  analysis.title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis.summary,
                  style: text.bodyMedium?.copyWith(
                    color: context.c.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _DetailSection(
            title: 'TEKNIKAL',
            icon: Icons.show_chart,
            initiallyExpanded: true,
            children: <Widget>[
              for (final TechnicalIndicator t in analysis.teknikal)
                _MetricRow(
                  name: t.name,
                  value: t.value,
                  interpretation: t.interpretation,
                  signal: t.signal,
                ),
            ],
          ),
          _DetailSection(
            title: 'FUNDAMENTAL',
            icon: Icons.account_balance_outlined,
            children: <Widget>[
              for (final FundamentalMetric f in analysis.fundamental)
                _MetricRow(
                  name: f.name,
                  value: f.value,
                  interpretation: f.interpretation,
                  signal: f.signal,
                ),
            ],
          ),
          _DetailSection(
            title: 'BERITA',
            icon: Icons.newspaper_outlined,
            children: <Widget>[
              for (final NewsHeadline n in analysis.berita)
                _NewsRow(headline: n),
            ],
          ),
          _DyorDisclaimer(text: analysis.disclaimer),
          ],
        ),
      ),
    );
  }
}

/// An expandable detail panel used for the analysis sections.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Removes the default divider lines so the card reads as one clean block.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: context.c.textSecondary,
        collapsedIconColor: context.c.textSecondary,
        leading: Icon(icon, size: 18, color: context.c.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: context.c.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
        children: children,
      ),
    );
  }
}

/// A single indicator or metric row: name, value, signal badge, interpretation.
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

/// A single news headline row with a source and sentiment badge.
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

/// The mandatory DYOR disclaimer, pinned at the bottom with a dashed top border.
/// There is no dismiss control by design.
class _DyorDisclaimer extends StatelessWidget {
  const _DyorDisclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: CustomPaint(
        painter: _DashedTopBorderPainter(color: context.c.surfaceLine),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 16,
                color: context.c.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.c.textSecondary,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed line along the top edge to separate the disclaimer.
class _DashedTopBorderPainter extends CustomPainter {
  const _DashedTopBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const double dashWidth = 4;
    const double dashGap = 4;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTopBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
