import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/models/stock_models.dart';
import '../../services/providers.dart';

/// Holds the chat conversation as a list of messages.
///
/// [sendMessage] appends the user's message, then subscribes to the chat
/// service stream. The service emits a thinking placeholder first and the final
/// assistant message with a populated analysis after. Each emission replaces the
/// pending assistant message so the UI shows the thinking indicator and then the
/// analysis card without duplicating rows.
class ChatController extends Notifier<List<ChatMessage>> {
  StreamSubscription<ChatMessage>? _sub;
  int _counter = 0;

  @override
  List<ChatMessage> build() {
    ref.onDispose(() {
      _sub?.cancel();
    });
    return const <ChatMessage>[];
  }

  bool get isThinking => state.any((ChatMessage m) => m.isThinking);

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  /// Sends a prompt to the mock chat service and streams the response.
  void sendMessage(String prompt, {String? ticker}) {
    final String trimmed = prompt.trim();
    if (trimmed.isEmpty || isThinking) {
      return;
    }

    final ChatMessage userMessage =
        ChatMessage.user(id: _nextId('user'), text: trimmed);
    state = <ChatMessage>[...state, userMessage];

    // Marks where the assistant reply will be appended so each emission can
    // replace it in place (thinking, then the final analysis).
    final String assistantId = _nextId('assistant');
    bool assistantAdded = false;

    _sub?.cancel();
    _sub = ref
        .read(chatServiceProvider)
        .sendMessage(trimmed, ticker: ticker)
        .listen((ChatMessage message) {
      final ChatMessage tagged = ChatMessage(
        id: assistantId,
        role: message.role,
        text: message.text,
        analysis: message.analysis,
        isThinking: message.isThinking,
      );
      if (!assistantAdded) {
        assistantAdded = true;
        state = <ChatMessage>[...state, tagged];
      } else {
        state = <ChatMessage>[
          for (final ChatMessage m in state)
            if (m.id == assistantId) tagged else m,
        ];
      }
    });
  }

  /// Clears the conversation.
  void reset() {
    _sub?.cancel();
    state = const <ChatMessage>[];
  }
}

/// The chat conversation state.
///
/// This is a plain (not autoDispose) provider on purpose. The AI tab lives in a
/// StatefulShellRoute.indexedStack, so its branch stays alive while the user
/// visits other tabs and an in-progress conversation is preserved when they
/// come back. A fresh conversation is started deliberately: opening the tab
/// from Home or Stock Detail passes a new seed or ticker, which remounts
/// ChatScreen (via its ValueKey) and calls reset() before seeding. Call reset()
/// to clear the conversation on demand.
final NotifierProvider<ChatController, List<ChatMessage>> chatControllerProvider =
    NotifierProvider<ChatController, List<ChatMessage>>(ChatController.new);
