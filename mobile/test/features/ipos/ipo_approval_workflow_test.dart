import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dirsha_mobile/core/money/money.dart';
import 'package:dirsha_mobile/core/theme/app_theme.dart';
import 'package:dirsha_mobile/features/ipos/models/ipo_models.dart';
import 'package:dirsha_mobile/features/ipos/providers/ipo_provider.dart';
import 'package:dirsha_mobile/features/ipos/repositories/ipo_repository.dart';
import 'package:dirsha_mobile/features/ipos/screens/ipo_detail_screen.dart';
import 'package:dirsha_mobile/shared/widgets/dirsha_button.dart';

class FakeIpoRepository implements IpoRepository {
  FakeIpoRepository({required this.detailToReturn});

  IpoDetail detailToReturn;
  int refreshCallCount = 0;

  @override
  Future<PaginatedIpos> getIpos({int page = 1, int pageSize = 20}) async {
    return PaginatedIpos(
      items: [detailToReturn],
      total: 1,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<IpoDetail> getIpoById(String id) async {
    refreshCallCount++;
    return detailToReturn;
  }
}

Widget createTestWidget(IpoRepository repo, String ipoId) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: ChangeNotifierProvider(
      create: (_) => IpoDetailProvider(repository: repo),
      child: IpoDetailScreen(ipoId: ipoId),
    ),
  );
}

void main() {
  group('IPO Approval & Subscription Workflow (Mobile)', () {
    testWidgets('Open IPO displays OPEN badge and enabled Subscribe button', (tester) async {
      final openDetail = IpoDetail(
        id: 'ipo-open-1',
        title: 'Open Public Offering',
        companyName: 'Open Horizons PLC',
        status: 'OPEN',
        pricePerShare: Money(5000),
        currency: 'ETB',
        subscriptionStartDate: DateTime.now().subtract(const Duration(hours: 2)),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 7)),
      );

      final fakeRepo = FakeIpoRepository(detailToReturn: openDetail);

      await tester.pumpWidget(createTestWidget(fakeRepo, openDetail.id));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 100)); // Complete load

      // Verification
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('Subscribe'), findsOneWidget);
      expect(
        find.text('Funds will be reserved from your wallet until allocation.'),
        findsOneWidget,
      );

      final buttonFinder = find.byType(DirshaButton);
      expect(buttonFinder, findsOneWidget);
      final dirshaButton = tester.widget<DirshaButton>(buttonFinder);
      expect(dirshaButton.isEnabled, isTrue);
    });

    testWidgets('Approved / Upcoming IPO displays APPROVED badge and disabled button', (tester) async {
      final approvedDetail = IpoDetail(
        id: 'ipo-approved-1',
        title: 'Scheduled Future Offering',
        companyName: 'NextGen Agritech S.C.',
        status: 'APPROVED',
        pricePerShare: Money(10000),
        currency: 'ETB',
        subscriptionStartDate: DateTime.now().add(const Duration(days: 3)),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 14)),
      );

      final fakeRepo = FakeIpoRepository(detailToReturn: approvedDetail);

      await tester.pumpWidget(createTestWidget(fakeRepo, approvedDetail.id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verification
      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('Subscriptions opening soon'), findsOneWidget);
      expect(
        find.textContaining('Subscriptions open on'),
        findsOneWidget,
      );

      final buttonFinder = find.byType(DirshaButton);
      expect(buttonFinder, findsOneWidget);
      final dirshaButton = tester.widget<DirshaButton>(buttonFinder);
      expect(dirshaButton.isEnabled, isFalse);
    });

    testWidgets('Closed IPO displays CLOSED badge and disabled Subscriptions closed button', (tester) async {
      final closedDetail = IpoDetail(
        id: 'ipo-closed-1',
        title: 'Closed Public Offering',
        companyName: 'Historic Mining PLC',
        status: 'CLOSED',
        pricePerShare: Money(7500),
        currency: 'ETB',
        subscriptionStartDate: DateTime.now().subtract(const Duration(days: 14)),
        subscriptionEndDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      final fakeRepo = FakeIpoRepository(detailToReturn: closedDetail);

      await tester.pumpWidget(createTestWidget(fakeRepo, closedDetail.id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verification
      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('Subscriptions closed'), findsOneWidget);
      expect(
        find.text('This offering is not currently accepting subscriptions.'),
        findsOneWidget,
      );

      final buttonFinder = find.byType(DirshaButton);
      expect(buttonFinder, findsOneWidget);
      final dirshaButton = tester.widget<DirshaButton>(buttonFinder);
      expect(dirshaButton.isEnabled, isFalse);
    });

    testWidgets('Pull to refresh invokes reload on provider and repository', (tester) async {
      final openDetail = IpoDetail(
        id: 'ipo-refresh-1',
        title: 'Refresh Test Offering',
        companyName: 'Dynamic Co',
        status: 'OPEN',
        pricePerShare: Money(5000),
        currency: 'ETB',
      );

      final fakeRepo = FakeIpoRepository(detailToReturn: openDetail);

      await tester.pumpWidget(createTestWidget(fakeRepo, openDetail.id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.refreshCallCount, 1);

      // Perform fling down to trigger RefreshIndicator
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.refreshCallCount, greaterThan(1));
    });
  });
}
