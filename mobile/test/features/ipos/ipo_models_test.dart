import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/features/ipos/models/ipo_models.dart';

void main() {
  group('IpoSummary.fromJson', () {
    final validJson = {
      'id': 'ipo-1',
      'title': 'Test IPO',
      'companyName': 'Test Corp',
      'status': 'OPEN',
      'pricePerShare': '100.00',
      'currency': 'ETB',
      'subscriptionStartDate': '2026-10-01T00:00:00.000Z',
      'subscriptionEndDate': '2026-11-30T00:00:00.000Z',
      'totalShares': 1000000,
      'availableShares': 600000,
      'minInvestment': '1000.00',
      'maxInvestment': '500000.00',
    };

    test('parses all fields', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.id, 'ipo-1');
      expect(ipo.companyName, 'Test Corp');
      expect(ipo.status, 'OPEN');
      expect(ipo.pricePerShare, '100.00');
      expect(ipo.currency, 'ETB');
      expect(ipo.totalShares, 1000000);
      expect(ipo.availableShares, 600000);
    });

    test('isOpen is true for OPEN status', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.isOpen, isTrue);
    });

    test('isOpen is false for CLOSED status', () {
      final ipo = IpoSummary.fromJson({...validJson, 'status': 'CLOSED'});
      expect(ipo.isOpen, isFalse);
    });

    test('isUpcoming is true for APPROVED status', () {
      final ipo = IpoSummary.fromJson({...validJson, 'status': 'APPROVED'});
      expect(ipo.isUpcoming, isTrue);
    });

    test('parses subscription dates', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.subscriptionStartDate, isNotNull);
      expect(ipo.subscriptionEndDate, isNotNull);
      expect(ipo.subscriptionStartDate!.year, 2026);
    });

    test('handles null optional fields gracefully', () {
      final minimal = {
        'id': 'ipo-2',
        'title': 'Minimal IPO',
        'companyName': 'Min Corp',
        'status': 'DRAFT',
        'pricePerShare': '50.00',
      };
      final ipo = IpoSummary.fromJson(minimal);
      expect(ipo.id, 'ipo-2');
      expect(ipo.subscriptionStartDate, isNull);
      expect(ipo.totalShares, isNull);
      expect(ipo.currency, 'ETB'); // default
    });

    test('handles malformed date without crashing', () {
      final json = {...validJson, 'subscriptionStartDate': 'not-a-date'};
      final ipo = IpoSummary.fromJson(json);
      expect(ipo.subscriptionStartDate, isNull);
    });
  });

  group('IpoDetail.fromJson', () {
    final detailJson = {
      'id': 'ipo-3',
      'title': 'Detail IPO',
      'companyName': 'Detail Corp',
      'status': 'OPEN',
      'pricePerShare': '200.00',
      'currency': 'ETB',
      'description': 'Full description here.',
      'companyDescription': 'Company info here.',
      'riskDisclosure': 'Past performance is not indicative of future results.',
      'subscribedShares': 400000,
    };

    test('parses detail-only fields', () {
      final detail = IpoDetail.fromJson(detailJson);
      expect(detail.description, 'Full description here.');
      expect(detail.riskDisclosure, isNotNull);
      expect(detail.subscribedShares, 400000);
    });

    test('inherits base IpoSummary fields', () {
      final detail = IpoDetail.fromJson(detailJson);
      expect(detail.companyName, 'Detail Corp');
      expect(detail.isOpen, isTrue);
    });

    test('handles missing documents gracefully', () {
      final detail = IpoDetail.fromJson(detailJson);
      expect(detail.documents, isNull);
    });
  });

  group('PaginatedIpos.fromJson', () {
    test('parses items list', () {
      final json = {
        'items': [
          {
            'id': 'i1',
            'title': 'T1',
            'companyName': 'C1',
            'status': 'OPEN',
            'pricePerShare': '10.00',
          },
          {
            'id': 'i2',
            'title': 'T2',
            'companyName': 'C2',
            'status': 'CLOSED',
            'pricePerShare': '20.00',
          },
        ],
        'total': 2,
        'page': 1,
        'pageSize': 20,
      };
      final paginated = PaginatedIpos.fromJson(json);
      expect(paginated.items.length, 2);
      expect(paginated.total, 2);
      expect(paginated.hasMore, isFalse);
    });

    test('handles empty items list', () {
      final json = {'items': [], 'total': 0, 'page': 1, 'pageSize': 20};
      final paginated = PaginatedIpos.fromJson(json);
      expect(paginated.items, isEmpty);
      expect(paginated.hasMore, isFalse);
    });

    test('accepts data key as alias for items', () {
      final json = {
        'data': [
          {
            'id': 'i1',
            'title': 'T',
            'companyName': 'C',
            'status': 'OPEN',
            'pricePerShare': '5.00',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 20,
      };
      final paginated = PaginatedIpos.fromJson(json);
      expect(paginated.items.length, 1);
    });
  });
}
