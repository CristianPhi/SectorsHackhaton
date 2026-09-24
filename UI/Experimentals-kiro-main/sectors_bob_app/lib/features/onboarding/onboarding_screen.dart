import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/teal_background.dart';

/// A single onboarding slide. Each carries a bespoke [preview] built from the
/// app's own UI vocabulary (a chat exchange, signal chips, a disclaimer card)
/// so the slide *shows* the feature instead of just describing it, plus a few
/// supporting [points] that add concrete substance under the body copy.
class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.points,
    required this.preview,
  });

  final String title;
  final String body;
  final List<String> points;
  final Widget preview;
}

final List<_Slide> _slides = <_Slide>[
  const _Slide(
    title: 'Tanya saham pakai bahasa sehari-hari',
    body:
        'Ketik pertanyaan seperti ngobrol biasa. BOB menjawab dengan bahasa yang gampang dimengerti, bukan istilah yang bikin pusing.',
    points: <String>[
      'Tanpa jargon yang bikin pusing',
      'Jawaban ringkas, langsung ke inti',
    ],
    preview: _ChatPreview(),
  ),
  const _Slide(
    title: 'Teknikal, fundamental, dan berita jadi satu',
    body:
        'Satu ringkasan menggabungkan sinyal teknikal, angka fundamental, dan sentimen berita terbaru, semuanya rapi dalam satu tampilan.',
    points: <String>[
      'Tiga sudut pandang dalam satu layar',
      'Sinyal yang mudah dibaca sekilas',
    ],
    preview: _SignalsPreview(),
  ),
  const _Slide(
    title: 'Selalu ingat, riset mandiri tetap penting',
    body:
        'BOB memberi konteks, bukan ajakan beli atau jual. Keputusan tetap di tangan kamu setelah melakukan riset mandiri (DYOR).',
    points: <String>[
      'Bukan ajakan beli atau jual',
      'Keputusan akhir tetap di tangan kamu',
    ],
    preview: _DyorPreview(),
  ),
];

/// Three swipeable intro slides with page indicators, Lewati and Lanjut
/// controls, and a Mulai button on the final slide that moves on to auth.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _finish() => context.go(AppRoutes.auth);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TealBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: context.c.textOnCanvas2,
                  ),
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (int value) => setState(() => _index = value),
                  itemBuilder: (BuildContext context, int i) {
                    return _SlideView(slide: _slides[i]);
                  },
                ),
              ),
              _Dots(count: _slides.length, active: _index),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: _isLast
                    ? PrimaryButton(label: 'Mulai', onPressed: _finish)
                    : GhostButton(label: 'Lanjut', onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out one slide: a bespoke preview up top, then title, body, and the
/// supporting detail bullets. Scrollable so it never overflows on short screens.
class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Center(child: slide.preview),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            style: text.headlineSmall?.copyWith(
              color: context.c.textOnCanvas,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            style: text.bodyLarge?.copyWith(
              color: context.c.textOnCanvas2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final String point in slide.points)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _CheckPoint(text: point),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// A gold check icon followed by a short supporting line.
class _CheckPoint extends StatelessWidget {
  const _CheckPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.check_circle_rounded,
            color: context.c.accent, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.c.textOnCanvas,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

/// A rounded panel used as the frame for each slide's preview illustration.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.c.bgElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: context.c.navBorder),
      ),
      child: child,
    );
  }
}

/// Slide 1 preview: a tiny chat exchange (user question -> BOB answer).
class _ChatPreview extends StatelessWidget {
  const _ChatPreview();

  @override
  Widget build(BuildContext context) {
    return const _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Bubble(
            text: 'BBCA lagi bagus nggak?',
            fromUser: true,
          ),
          SizedBox(height: AppSpacing.xs),
          _Bubble(
            text:
                'Secara teknikal netral, fundamental kuat, sentimen berita positif. '
                'Ini konteksnya, bukan ajakan beli ya.',
            fromUser: false,
          ),
        ],
      ),
    );
  }
}

/// A single chat bubble. User bubbles are gold and align right; BOB bubbles are
/// the off-white surface and align left.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: fromUser ? context.c.accent : context.c.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fromUser ? context.c.textOnAccent : context.c.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.35,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Slide 2 preview: three labeled signal chips (Teknikal / Fundamental /
/// Berita) with mini bullish/neutral/positive badges, mirroring the real
/// stock-detail signal look.
class _SignalsPreview extends StatelessWidget {
  const _SignalsPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        children: <Widget>[
          _SignalRow(
            label: 'Teknikal',
            value: 'Netral',
            tint: context.c.surfaceAlt,
            color: context.c.textSecondary,
            icon: Icons.trending_flat,
          ),
          SizedBox(height: AppSpacing.xs),
          _SignalRow(
            label: 'Fundamental',
            value: 'Kuat',
            tint: context.c.bullishTint,
            color: context.c.bullishOnSurface,
            icon: Icons.trending_up,
          ),
          SizedBox(height: AppSpacing.xs),
          _SignalRow(
            label: 'Berita',
            value: 'Positif',
            tint: context.c.bullishTint,
            color: context.c.bullishOnSurface,
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

/// One row in the signals preview: a label on an off-white card with a small
/// tinted signal badge on the right.
class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.label,
    required this.value,
    required this.tint,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tint;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 3 preview: a shield callout reinforcing the DYOR / not-advice message.
class _DyorPreview extends StatelessWidget {
  const _DyorPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.c.accentTint,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: context.c.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bukan nasihat keuangan',
                  style: TextStyle(
                    color: context.c.textOnCanvas,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'BOB kasih konteks. Do Your Own Research (DYOR) '
                  'sebelum ambil keputusan.',
                  style: TextStyle(
                    color: context.c.textOnCanvas2,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator dots. The active dot uses the gold accent.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int i) {
        final bool isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 22 : 8,
          decoration: BoxDecoration(
            color: isActive ? context.c.accent : context.c.textOnCanvas2,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
        );
      }),
    );
  }
}
