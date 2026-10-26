import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/ai_models.dart';
import '../repositories/ai_repository.dart';

class AiChatProvider extends ChangeNotifier {
  AiChatProvider({required this._repository});
  final AiRepository _repository;
  final List<ChatMessage> _messages = [];
  bool isSending = false;
  String language = 'en';
  String? error;
  String? _ipoId;
  String? _lastMessage;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  void setIpo(String? id) => _ipoId = id;
  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  Future<void> send(String message) async {
    if (message.trim().isEmpty || isSending) return;
    _lastMessage = message.trim();
    error = null;
    isSending = true;
    final history = List<ChatMessage>.from(_messages);
    _messages.add(ChatMessage(content: message.trim(), isUser: true));
    notifyListeners();
    try {
      final answer = await _repository.ask(
        message: message.trim(),
        language: language,
        ipoId: _ipoId,
        history: history.length > 6
            ? history.sublist(history.length - 6)
            : history,
      );
      _messages.add(ChatMessage(content: '', isUser: false, answer: answer));
      for (var index = 0; index < answer.answer.length; index++) {
        if (!isSending) break;
        _messages[_messages.length - 1] = _messages.last.copyWith(
          content: answer.answer.substring(0, index + 1),
        );
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 18));
      }
    } on ApiException catch (e) {
      error = e.statusCode == 429
          ? 'You are sending messages too fast.'
          : e.statusCode >= 500
          ? 'The assistant is temporarily unavailable.'
          : e.message;
    } on UnauthorizedException catch (e) {
      error = e.message;
    } on NetworkException catch (e) {
      error = e.message;
    } on TimeoutException catch (e) {
      error = e.message;
    } on AppException catch (e) {
      error = e.message;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    final message = _lastMessage;
    if (message != null) await send(message);
  }

  void clear() {
    _messages.clear();
    error = null;
    notifyListeners();
  }
}
