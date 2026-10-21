import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/money/money.dart';
import 'package:dirsha_mobile/core/utils/formatters.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Formatters.money — primary display path
  // ---------------------------------------------------------------------------
  group('Formatters.money', () {
    test('700000 santim displays as ETB 7,000.00', () {
      final result = Formatters.money(Money(700000));
      expect(result, 'ETB 7,000.00');
    });

    test('10000 santim displays as ETB 100.00', () {
      expect(Formatters.money(Money(10000)), 'ETB 100.00');
    });

    test('5000 santim displays as ETB 50.00', () {
      expect(Formatters.money(Money(5000)), 'ETB 50.00');
    });

    test('1000000 santim displays as ETB 10,000.00', () {
      expect(Formatters.money(Money(1000000)), 'ETB 10,000.00');
    });

    test('50 santim displays as ETB 0.50', () {
      expect(Formatters.money(Money(50)), 'ETB 0.50');
    });

    test('zero displays as ETB 0.00', () {
      expect(Formatters.money(Money.zero), 'ETB 0.00');
    });

    test('custom symbol is applied', () {
      final result = Formatters.money(Money(700000), symbol: 'Br');
      expect(result, contains('7,000.00'));
      expect(result, contains('Br'));
    });

    // Critical regression: must never show 700,000 for 700000 santim
    test('700000 santim does NOT display as ETB 700,000.00', () {
      final result = Formatters.money(Money(700000));
      expect(result, isNot(contains('700,000')));
      expect(result, contains('7,000'));
    });
  });

  // ---------------------------------------------------------------------------
  // Formatters.currency — legacy string path
  // ---------------------------------------------------------------------------
  group('Formatters.currency — decimal ETB string', () {
    test('"7000.00" displays as ETB 7,000.00', () {
      expect(Formatters.currency('7000.00'), 'ETB 7,000.00');
    });

    test('"100.00" displays as ETB 100.00', () {
      expect(Formatters.currency('100.00'), 'ETB 100.00');
    });
  });

  group('Formatters.currency — santim integer string', () {
    test('"700000" treated as santim → ETB 7,000.00', () {
      expect(Formatters.currency('700000'), 'ETB 7,000.00');
    });

    test('"10000" → ETB 100.00', () {
      expect(Formatters.currency('10000'), 'ETB 100.00');
    });
  });

  group('Formatters.currency — edge cases', () {
    test('empty string returns symbol + 0.00', () {
      final result = Formatters.currency('');
      expect(result, contains('0.00'));
    });

    test('invalid string falls back gracefully', () {
      final result = Formatters.currency('not-a-number');
      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Formatters.compact
  // ---------------------------------------------------------------------------
  group('Formatters.compact', () {
    test('1200000 → "1.2M"', () {
      expect(Formatters.compact(1200000), '1.2M');
    });

    test('1000 → "1K"', () {
      expect(Formatters.compact(1000), '1K');
    });
  });

  // ---------------------------------------------------------------------------
  // Date formatters
  // ---------------------------------------------------------------------------
  group('Formatters.dateShort', () {
    test('formats date correctly', () {
      final date = DateTime(2026, 10, 20);
      expect(Formatters.dateShort(date), 'Oct 20, 2026');
    });
  });

  group('Formatters.dateMedium', () {
    test('formats date correctly', () {
      final date = DateTime(2026, 10, 20);
      expect(Formatters.dateMedium(date), 'October 20, 2026');
    });
  });
}
