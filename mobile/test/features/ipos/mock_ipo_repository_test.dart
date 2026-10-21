import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/ipos/repositories/mock_ipo_repository.dart';

void main() {
  late MockIpoRepository repo;

  setUp(() => repo = MockIpoRepository());

  group('MockIpoRepository.getIpos', () {
    test('returns non-empty list', () async {
      final result = await repo.getIpos();
      expect(result.items, isNotEmpty);
    });

    test('items include OPEN, UPCOMING, and CLOSED statuses', () async {
      final result = await repo.getIpos();
      final statuses = result.items.map((i) => i.status).toSet();
      expect(statuses, containsAll(['OPEN', 'UPCOMING', 'CLOSED']));
    });

    test('total matches item count', () async {
      final result = await repo.getIpos();
      expect(result.total, result.items.length);
    });
  });

  group('MockIpoRepository.getIpoById', () {
    test('returns OPEN IPO detail', () async {
      final detail = await repo.getIpoById('mock-ipo-001');
      expect(detail.id, 'mock-ipo-001');
      expect(detail.isOpen, isTrue);
      expect(detail.description, isNotNull);
      expect(detail.riskDisclosure, isNotNull);
    });

    test('returns UPCOMING IPO detail', () async {
      final detail = await repo.getIpoById('mock-ipo-002');
      expect(detail.status, 'UPCOMING');
    });

    test('throws ArgumentError for unknown id', () async {
      await expectLater(
        repo.getIpoById('non-existent-id'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
