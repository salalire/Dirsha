import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/money/money.dart';
import 'package:dirsha_mobile/features/ipos/models/ipo_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // IpoSummary.fromJson — legacy ETB string format (mock data)
  // ---------------------------------------------------------------------------
  group('IpoSummary.fromJson — legacy ETB string format', () {
    final validJson = {
      'id': 'ipo-1',
      'title': 'Test IPO',
      'companyName': 'Test Corp',
      'status': 'OPEN',
      'pricePerShare': '100.00', // ETB decimal string → 10000 santim
      'currency': 'ETB',
      'subscriptionStartDate': '2026-10-01T00:00:00.000Z',
      'subscriptionEndDate': '2026-11-30T00:00:00.000Z',
      'totalShares': 1000000,
      'availableShares': 600000,
      'minInvestment': '1000.00', // → 100000 santim
      'maxInvestment': '500000.00', // → 50000000 santim
    };

    test('parses non-monetary fields', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.id, 'ipo-1');
      expect(ipo.companyName, 'Test Corp');
      expect(ipo.status, 'OPEN');
      expect(ipo.currency, 'ETB');
      expect(ipo.totalShares, 1000000);
      expect(ipo.availableShares, 600000);
    });

    test('pricePerShare "100.00" ETB string → 10000 santim', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.pricePerShare.santim, 10000);
      expect(ipo.pricePerShare.etb, 100.0);
    });

    test('minInvestment "1000.00" → 100000 santim', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.minInvestment!.santim, 100000);
      expect(ipo.minInvestment!.etb, 1000.0);
    });

    test('maxInvestment "500000.00" → 50000000 santim', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.maxInvestment!.santim, 50000000);
    });

    test('isOpen is true for OPEN status', () {
      expect(IpoSummary.fromJson(validJson).isOpen, isTrue);
    });

    test('isOpen is false for CLOSED status', () {
      expect(
        IpoSummary.fromJson({...validJson, 'status': 'CLOSED'}).isOpen,
        isFalse,
      );
    });

    test('isUpcoming is true for APPROVED status', () {
      expect(
        IpoSummary.fromJson({...validJson, 'status': 'APPROVED'}).isUpcoming,
        isTrue,
      );
    });

    test('parses subscription dates', () {
      final ipo = IpoSummary.fromJson(validJson);
      expect(ipo.subscriptionStartDate, isNotNull);
      expect(ipo.subscriptionEndDate, isNotNull);
      expect(ipo.subscriptionStartDate!.year, 2026);
    });

    test('handles malformed date without crashing', () {
      final ipo = IpoSummary.fromJson({
        ...validJson,
        'subscriptionStartDate': 'not-a-date',
      });
      expect(ipo.subscriptionStartDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // IpoSummary.fromJson — live API santim integer format
  // ---------------------------------------------------------------------------
  group('IpoSummary.fromJson — live API santim integer format', () {
    final santimJson = {
      'id': 'ipo-2',
      'title': 'Live IPO',
      'companyName': 'Live Corp',
      'status': 'OPEN',
      'price_per_share_minor': 10000, // 10000 santim = ETB 100.00
      'currency': 'ETB',
      'min_investment_minor': 100000, // ETB 1000.00
      'max_investment_minor': 50000000, // ETB 500000.00
    };

    test('parses price_per_share_minor as Money', () {
      final ipo = IpoSummary.fromJson(santimJson);
      expect(ipo.pricePerShare.santim, 10000);
      expect(ipo.pricePerShare.etb, 100.0);
    });

    test('parses min/max investment from _minor fields', () {
      final ipo = IpoSummary.fromJson(santimJson);
      expect(ipo.minInvestment!.santim, 100000);
      expect(ipo.maxInvestment!.santim, 50000000);
    });

    test('10000 santim is ETB 100, not ETB 10000', () {
      final ipo = IpoSummary.fromJson(santimJson);
      expect(ipo.pricePerShare.etb, 100.0);
      expect(ipo.pricePerShare.etb, isNot(10000.0));
    });
  });

  // ---------------------------------------------------------------------------
  // IpoSummary — null optional fields
  // ---------------------------------------------------------------------------
  group('IpoSummary.fromJson — null optional fields', () {
    final minimal = {
      'id': 'ipo-3',
      'title': 'Minimal IPO',
      'companyName': 'Min Corp',
      'status': 'DRAFT',
      'pricePerShare': '50.00',
    };

    test('handles absent optional fields gracefully', () {
      final ipo = IpoSummary.fromJson(minimal);
      expect(ipo.id, 'ipo-3');
      expect(ipo.subscriptionStartDate, isNull);
      expect(ipo.totalShares, isNull);
      expect(ipo.minInvestment, isNull);
      expect(ipo.currency, 'ETB');
    });
  });

  // ---------------------------------------------------------------------------
  // IpoDetail.fromJson
  // ---------------------------------------------------------------------------
  group('IpoDetail.fromJson', () {
    final detailJson = {
      'id': 'ipo-4',
      'title': 'Detail IPO',
      'companyName': 'Detail Corp',
      'status': 'OPEN',
      'pricePerShare': '200.00',
      'currency': 'ETB',
      'description': 'Full description here.',
      'companyDescription': 'Company info here.',
      'riskDisclosure': 'Past performance does not indicate future results.',
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
      expect(detail.pricePerShare.santim, 20000); // "200.00" ETB → 20000 santim
    });

    test('handles missing documents gracefully', () {
      expect(IpoDetail.fromJson(detailJson).documents, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PaginatedIpos.fromJson
  // ---------------------------------------------------------------------------
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
      expect(PaginatedIpos.fromJson(json).items, isEmpty);
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
      expect(PaginatedIpos.fromJson(json).items.length, 1);
    });

    test('parses santim integer items', () {
      final json = {
        'items': [
          {
            'id': 'i1',
            'title': 'T',
            'companyName': 'C',
            'status': 'OPEN',
            'price_per_share_minor': 10000,
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 20,
      };
      final paginated = PaginatedIpos.fromJson(json);
      expect(paginated.items.first.pricePerShare, equals(Money(10000)));
    });
  });
}
