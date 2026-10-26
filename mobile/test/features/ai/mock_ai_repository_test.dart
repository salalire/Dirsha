import 'package:dirsha_mobile/features/ai/repositories/mock_ai_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAiRepository repo;

  setUp(() => repo = MockAiRepository());

  test('answers glossary questions as simulated educational text', () async {
    final answer = await repo.ask(message: 'What is an IPO?', language: 'en');
    expect(answer.simulated, isTrue);
    expect(answer.grounded, isFalse);
    expect(answer.disclaimer, contains('not financial advice'));
    expect(answer.answer.toLowerCase(), contains('ipo'));
  });

  test('refuses action requests without claiming to trade', () async {
    final answer = await repo.ask(
      message: 'Buy 10 shares of this IPO',
      language: 'en',
    );
    expect(answer.grounded, isFalse);
    expect(answer.answer.toLowerCase(), contains('cannot buy'));
  });

  test('grounds mock IPO context when ipoId is supplied', () async {
    final answer = await repo.ask(
      message: 'Summarize this offering',
      language: 'en',
      ipoId: 'mock-ipo-001',
    );
    expect(answer.grounded, isTrue);
    expect(answer.sources.single.ipoId, 'mock-ipo-001');
    expect(answer.simulated, isTrue);
  });
}
