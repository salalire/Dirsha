import 'package:dirsha_mobile/features/ai/models/ai_models.dart';
import 'package:dirsha_mobile/features/ai/providers/ai_chat_provider.dart';
import 'package:dirsha_mobile/features/ai/repositories/ai_repository.dart';
import 'package:dirsha_mobile/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiRepository implements AiRepository {
  int calls = 0;
  bool fail = false;

  @override
  Future<AiAnswer> ask({
    required String message,
    required String language,
    String? ipoId,
    List<ChatMessage> history = const [],
  }) async {
    calls++;
    if (fail) throw const NetworkException();
    return AiAnswer(
      answer: 'Answer to $message',
      language: language,
      grounded: false,
      sources: const [],
      disclaimer: AiAnswer.disclaimerFor(language),
      simulated: true,
    );
  }
}

void main() {
  test('sends and clears chat, keeping the latest six history turns', () async {
    final repository = _FakeAiRepository();
    final provider = AiChatProvider(repository: repository);

    await provider.send('first');
    expect(provider.messages, hasLength(2));
    expect(provider.isSending, isFalse);

    for (var i = 0; i < 7; i++) {
      await provider.send('message $i');
    }
    expect(repository.calls, 8);
    provider.clear();
    expect(provider.messages, isEmpty);
    expect(provider.error, isNull);
  });

  test('retries after an error', () async {
    final repository = _FakeAiRepository()..fail = true;
    final provider = AiChatProvider(repository: repository);

    await provider.send('retry me');
    expect(provider.error, isNotNull);
    repository.fail = false;
    await provider.retry();
    expect(provider.error, isNull);
    expect(provider.messages.last.answer, isNotNull);
  });
}
