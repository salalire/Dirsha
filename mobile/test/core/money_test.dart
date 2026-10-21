import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/money/money.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------
  group('Money construction', () {
    test('stores santim as int', () {
      const m = Money(700000);
      expect(m.santim, 700000);
    });

    test('zero constant is 0 santim', () {
      expect(Money.zero.santim, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — integer santim (live API format)
  // ---------------------------------------------------------------------------
  group('Money.fromJson — integer santim', () {
    test('700000 santim → ETB 7000.00', () {
      final m = Money.fromJson(700000);
      expect(m.santim, 700000);
      expect(m.etb, 7000.0);
    });

    test('10000 santim → ETB 100.00', () {
      final m = Money.fromJson(10000);
      expect(m.santim, 10000);
      expect(m.etb, 100.0);
    });

    test('50 santim → ETB 0.50', () {
      final m = Money.fromJson(50);
      expect(m.santim, 50);
      expect(m.etb, closeTo(0.5, 0.001));
    });

    test('0 → Money.zero', () {
      final m = Money.fromJson(0);
      expect(m.santim, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — decimal ETB string (legacy mock format)
  // ---------------------------------------------------------------------------
  group('Money.fromJson — decimal ETB string (legacy mock)', () {
    test('"7000.00" treated as ETB → 700000 santim', () {
      final m = Money.fromJson('7000.00');
      expect(m.santim, 700000);
    });

    test('"100.00" → 10000 santim', () {
      final m = Money.fromJson('100.00');
      expect(m.santim, 10000);
    });

    test('"0.50" → 50 santim', () {
      final m = Money.fromJson('0.50');
      expect(m.santim, 50);
    });

    test('"10000.00" → 1000000 santim', () {
      final m = Money.fromJson('10000.00');
      expect(m.santim, 1000000);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — integer string (santim as string)
  // ---------------------------------------------------------------------------
  group('Money.fromJson — integer string', () {
    test('"700000" treated as santim → ETB 7000.00', () {
      final m = Money.fromJson('700000');
      expect(m.santim, 700000);
      expect(m.etb, 7000.0);
    });

    test('"10000" → ETB 100.00', () {
      final m = Money.fromJson('10000');
      expect(m.santim, 10000);
      expect(m.etb, 100.0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — null and invalid
  // ---------------------------------------------------------------------------
  group('Money.fromJson — null and invalid', () {
    test('null → Money.zero', () {
      expect(Money.fromJson(null).santim, 0);
    });

    test('empty string → Money.zero', () {
      expect(Money.fromJson('').santim, 0);
    });

    test('non-numeric string → Money.zero', () {
      expect(Money.fromJson('not-a-number').santim, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ETB display conversion
  // ---------------------------------------------------------------------------
  group('Money.etb — display only', () {
    test('1 santim = ETB 0.01', () {
      expect(Money(1).etb, closeTo(0.01, 0.0001));
    });

    test('100 santim = ETB 1.00', () {
      expect(Money(100).etb, 1.0);
    });

    test('1000000 santim = ETB 10000.00', () {
      expect(Money(1000000).etb, 10000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // toJson — serializes back to santim int
  // ---------------------------------------------------------------------------
  group('Money.toJson', () {
    test('serializes to santim integer', () {
      expect(Money(700000).toJson(), 700000);
    });

    test('Money.zero serializes to 0', () {
      expect(Money.zero.toJson(), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('Money equality', () {
    test('same santim values are equal', () {
      expect(Money(700000), equals(Money(700000)));
    });

    test('different santim values are not equal', () {
      expect(Money(700000), isNot(equals(Money(700001))));
    });
  });

  // ---------------------------------------------------------------------------
  // Comparison operators
  // ---------------------------------------------------------------------------
  group('Money comparison', () {
    test('greater than', () {
      expect(Money(700000) > Money(600000), isTrue);
    });

    test('less than', () {
      expect(Money(600000) < Money(700000), isTrue);
    });

    test('greater than or equal — equal', () {
      expect(Money(700000) >= Money(700000), isTrue);
    });

    test('less than or equal — less', () {
      expect(Money(500000) <= Money(700000), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Critical: 700000 santim must NOT display as ETB 700,000
  // ---------------------------------------------------------------------------
  group('Money — santim/ETB conversion correctness', () {
    test('700000 santim is ETB 7000.00 not ETB 700000.00', () {
      final m = Money(700000);
      // etb must be 7000, not 700000
      expect(m.etb, 7000.0);
      expect(m.etb, isNot(700000.0));
    });

    test('fromJson(700000 int) is same as fromJson("7000.00" ETB string)', () {
      final fromInt = Money.fromJson(700000);
      final fromStr = Money.fromJson('7000.00');
      expect(fromInt, equals(fromStr));
    });
  });
}
