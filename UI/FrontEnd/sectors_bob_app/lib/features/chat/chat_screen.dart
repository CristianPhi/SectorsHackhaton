import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bob_colors.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../core/widgets/teal_background.dart';
import '../../services/models/analysis_models.dart';
import '../../services/models/stock_models.dart';
import 'chat_controller.dart';
import 'widgets/analysis_card.dart';

/// Example prompts shown in the empty chat state, mirroring the tone of the
/// suggestions on Home so the two entry points feel like one product.
const List<String> _emptyStateQuestions = <String>[
  'Bagaimana TLKM hari ini?',
  'Bandingkan BBCA dan BBRI',
  'Jelaskan apa itu RSI',
];

/// The AI chat screen.
///
/// Teal conversation canvas with a header, a scrolling message list, an animated
/// thinking indicator, and a rounded input with a gold circular send button. It
/// accepts an optional [seed] prompt and [ticker] so it can open pre-seeded from
/// Home or Stock Detail and send the first message automatically.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.seed, this.ticker});

  final String? seed;
  final String? ticker;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Seed the conversation once the first frame is ready so the controller and
    // providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSeed());
  }

  void _maybeSeed() {
    final String? seed = widget.seed?.trim();
    final String? ticker = widget.ticker?.trim();
    if ((seed == null || seed.isEmpty) && (ticker == null || ticker.isEmpty)) {
      return;
    }
    final String prompt = (seed != null && seed.isNotEmpty)
        ? seed
        : 'Tolong analisis saham $ticker';
    // Opening the chat with a new seed starts a fresh conversation.
    final ChatController controller =
        ref.read(chatControllerProvider.notifier);
    controller.reset();
    controller.sendMessage(prompt, ticker: ticker);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _input.text.trim();
    if (text.isEmpty) {
      return;
    }
    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _input.clear();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) {
      return;
    }
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatMessage> messages = ref.watch(chatControllerProvider);
    ref.listen<List<ChatMessage>>(chatControllerProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TealBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const _ChatHeader(),
            Expanded(
              child: messages.isEmpty
                  ? _EmptyState(
                      onSelected: (String q) {
                        ref.read(chatControllerProvider.notifier).sendMessage(q);
                      },
                    )
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final ChatMessage message = messages[index];
                        // Key the entrance by message id so each bubble plays
                        // its fade + slide once when it first appears, rather
                        // than replaying on every list rebuild. No stagger:
                        // messages arrive one at a time at the bottom.
                        return AnimatedEntrance(
                          key: ValueKey<String>('msg-${message.id}'),
                          child: _MessageBubble(message: message),
                        );
                      },
                    ),
            ),
            _ChatInput(controller: _input, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chat header: BOB AI title, a green online status, and a gold B avatar.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.c.bgBase,
        border: Border(bottom: BorderSide(color: context.c.bgSunken)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.c.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'B',
              style: TextStyle(
                color: context.c.textOnAccent,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'BOB AI',
                style: text.titleMedium?.copyWith(
                  color: context.c.textOnCanvas,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: <Widget>[
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: context.c.bullish,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: text.bodySmall?.copyWith(
                      color: context.c.textOnCanvas2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown before any message is sent. Carries the same suggested-question
/// pattern as Home so the empty tab is not just a blank teal field.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_outlined,
                  color: context.c.accent,
                  size: 36,
                ),
                const SizedBox(height: 14),
                Text(
                  'Tanya saham apa saja',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    color: context.c.textOnCanvas,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dapat jawaban yang dimengerti, lengkap dengan sinyal '
                  'teknikal, fundamental, dan berita.',
                  textAlign: TextAlign.center,
                  style:
                      text.bodyMedium?.copyWith(color: context.c.textOnCanvas2),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _emptyStateQuestions.map((String q) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                      onTap: () => onSelected(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusPill),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renders one message. User messages are gold bubbles aligned right. Assistant
/// messages are either the thinking indicator or an analysis card.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.c.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppColors.radiusCard),
                topRight: Radius.circular(AppColors.radiusCard),
                bottomLeft: Radius.circular(AppColors.radiusCard),
                bottomRight: Radius.circular(AppColors.radiusSmall),
              ),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(
                color: context.c.textOnAccent,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    if (message.isThinking) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: _ThinkingIndicator(),
      );
    }

    final StockAnalysis? analysis = message.analysis;
    if (analysis == null) {
      return const SizedBox.shrink();
    }
    return AnalysisCard(analysis: analysis);
  }
}

/// An animated three-dot thinking indicator with a short status label.
class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: context.c.surfaceLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (int i) {
                  final double t = (_controller.value + i * 0.2) % 1.0;
                  final double opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                          color: context.c.accentPress,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            'BOB sedang menganalisis...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// The bottom input: a rounded surface field with a gold circular send button.
class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: context.c.bgBase,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.c.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                border: Border.all(color: context.c.surfaceLine),
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan kamu',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: context.c.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.send_rounded,
                  color: context.c.textOnAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
