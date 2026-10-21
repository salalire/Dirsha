import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/shared/widgets/status_badge.dart';
import 'package:dirsha_mobile/core/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('StatusBadge.fromString variant mapping', () {
    test('OPEN maps to success', () {
      final badge = StatusBadge.fromString('OPEN');
      expect(badge.variant, BadgeVariant.success);
    });

    test('CLOSED maps to error', () {
      final badge = StatusBadge.fromString('CLOSED');
      expect(badge.variant, BadgeVariant.error);
    });

    test('PENDING maps to warning', () {
      final badge = StatusBadge.fromString('PENDING');
      expect(badge.variant, BadgeVariant.warning);
    });

    test('DRAFT maps to info', () {
      final badge = StatusBadge.fromString('DRAFT');
      expect(badge.variant, BadgeVariant.info);
    });

    test('unknown status maps to neutral', () {
      final badge = StatusBadge.fromString('UNKNOWN_STATUS_XYZ');
      expect(badge.variant, BadgeVariant.neutral);
    });

    test('case-insensitive: open maps to success', () {
      final badge = StatusBadge.fromString('open');
      expect(badge.variant, BadgeVariant.success);
    });

    test('ALLOCATED maps to success', () {
      final badge = StatusBadge.fromString('ALLOCATED');
      expect(badge.variant, BadgeVariant.success);
    });

    test('SUBMITTED maps to warning', () {
      final badge = StatusBadge.fromString('SUBMITTED');
      expect(badge.variant, BadgeVariant.warning);
    });

    test('CANCELLED maps to error', () {
      final badge = StatusBadge.fromString('CANCELLED');
      expect(badge.variant, BadgeVariant.error);
    });
  });

  group('StatusBadge widget rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(StatusBadge.fromString('OPEN')));
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('renders with correct uppercase label', (tester) async {
      await tester.pumpWidget(_wrap(StatusBadge.fromString('pending')));
      expect(find.text('PENDING'), findsOneWidget);
    });
  });
}
