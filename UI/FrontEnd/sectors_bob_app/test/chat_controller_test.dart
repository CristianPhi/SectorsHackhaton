import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sectors_bob_app/features/chat/chat_controller.dart';
import 'package:sectors_bob_app/services/models/stock_models.dart';

void main() {
  test('sendMessage moves state from user to thinking to analysis in place',
      () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ChatController controller =
        container.read(chatControllerProvider.notifier);

    controller.sendMessage('Bagaimana BBCA hari ini?', ticker: 'BBCA');

    // The user row is appended synchronously when sendMessage is called.
    List<ChatMessage> state = container.read(chatControllerProvider);
    expect(state.length, 1);
    expect(state.first.isUser, isTrue);
    expect(state.first.text, 'Bagaimana BBCA hari ini?');

    // The mock stream delivers the thinking message on a later microtask, so
    // let the event loop turn before asserting the thinking state.
    await Future<void>.delayed(Duration.zero);

    state = container.read(chatControllerProvider);
    expect(state.length, 2);
    expect(state.last.isUser, isFalse);
    expect(state.last.isThinking, isTrue);
    expect(state.last.analysis, isNull);

    final String assistantId = state.last.id;

    // Wait past the mock think time for the final analysis emission.
    await Future<void>.delayed(const Duration(seconds: 2));

    state = container.read(chatControllerProvider);
    // The assistant row is replaced in place, not duplicated: still two rows.
    expect(state.length, 2);
    expect(state.first.isUser, isTrue);
    expect(state.last.id, assistantId);
    expect(state.last.isThinking, isFalse);
    expect(state.last.analysis, isNotNull);
    expect(state.last.analysis!.ticker, 'BBCA');
  });

  test('sendMessage ignores an empty prompt', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ChatController controller =
        container.read(chatControllerProvider.notifier);

    controller.sendMessage('   ');

    expect(container.read(chatControllerProvider), isEmpty);
  });

  test('reset clears the conversation', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ChatController controller =
        container.read(chatControllerProvider.notifier);

    controller.sendMessage('analisis TLKM', ticker: 'TLKM');
    expect(container.read(chatControllerProvider), isNotEmpty);

    controller.reset();
    expect(container.read(chatControllerProvider), isEmpty);
  });
}
