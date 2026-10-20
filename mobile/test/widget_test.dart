// Dirsha Phase 1 — top-level app smoke test.
//
// Verifies that the app widget tree inflates without a crash.
// Full end-to-end navigation tests require a running device/emulator
// and are out of scope for this CI-friendly test suite.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dirsha_mobile/core/theme/app_theme.dart';
import 'package:dirsha_mobile/shared/widgets/loading_indicator.dart';

void main() {
  testWidgets('LoadingIndicator.fullScreen renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: LoadingIndicator.fullScreen(message: 'Loading…'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
  });

  testWidgets('LoadingIndicator.inline renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: LoadingIndicator.inline()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
