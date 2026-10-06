import '../models/stock_models.dart';

/// Chat contract. Sending a message returns a stream that first emits a thinking
/// message, then the final message carrying a structured [StockAnalysis].
abstract class ChatService {
  Stream<ChatMessage> sendMessage(String prompt, {String? ticker});
}
