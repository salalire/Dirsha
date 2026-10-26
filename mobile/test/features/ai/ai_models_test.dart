import 'package:dirsha_mobile/features/ai/models/ai_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses backend chat envelope', () {
    final answer = AiAnswer.fromJson({
      'data': {
        'answer': 'An IPO is an initial public offering.',
        'language': 'en',
        'grounded': false,
        'sources': [],
        'disclaimer': 'Educational information only.',
        'simulated': true,
        'request_id': 'req-1',
      },
    });
    expect(answer.answer, contains('IPO'));
    expect(answer.simulated, isTrue);
    expect(answer.sources, isEmpty);
  });

  test('parses grounded sources', () {
    final answer = AiAnswer.fromJson({
      'answer': 'From Dirsha data: Dev Corp A.',
      'language': 'en',
      'grounded': true,
      'sources': [
        {
          'label': 'DVCA IPO',
          'type': 'ipo',
          'ipo_id': '11111111-1111-1111-1111-111111111111',
          'as_of': '2026-10-26T00:00:00.000Z',
        },
      ],
      'disclaimer': 'Educational information only.',
      'simulated': false,
    });
    expect(answer.grounded, isTrue);
    expect(answer.simulated, isFalse);
    expect(answer.sources.single.ipoId, '11111111-1111-1111-1111-111111111111');
  });
}
