import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/widgets/subscription_card.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 13, 9);
  final today = LogicalDay(2026, 11, 13);
  late FakeStoreRepository store;

  final annual = Entitled(
    plan: PlanKind.annual,
    expiresAt: DateTime(2026, 12, 3, 10),
    inTrial: false,
  );

  Future<void> openSettings(WidgetTester tester, Access access) async {
    store = FakeStoreRepository(access: access, now: () => now);
    await setUpTestDependencies(FixedClock(now), store: store);
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
    );
    await tester.pumpAppPastSplash(height: 2400);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionCard), findsOneWidget);
  }

  Future<void> tapAndShowSnack(WidgetTester tester, String label) async {
    await tester.scrollAndTap(find.text(label));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  tearDown(InjectionContainer.reset);

  testWidgets('Annual is paid until its date', (tester) async {
    await openSettings(tester, annual);

    expect(find.text(PaywallCopy.subscriptionTitle), findsOneWidget);
    expect(find.text(PaywallCopy.annual), findsOneWidget);
    expect(
      find.text('Paid until ${AppFormat.monthDay(LogicalDay(2026, 12, 3))}'),
      findsOneWidget,
    );
    expect(find.text(PaywallCopy.manageSubscription), findsOneWidget);
    expect(find.text(PaywallCopy.restorePurchases), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the trial is free until its date', (tester) async {
    await openSettings(
      tester,
      Entitled(
        plan: PlanKind.annual,
        expiresAt: DateTime(2026, 11, 20, 10),
        inTrial: true,
      ),
    );

    expect(
      find.text('Free until ${AppFormat.monthDay(LogicalDay(2026, 11, 20))}'),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Lifetime is yours for good, with nothing to manage', (
    tester,
  ) async {
    await openSettings(
      tester,
      const Entitled(plan: PlanKind.lifetime, expiresAt: null, inTrial: false),
    );

    expect(find.text(PaywallCopy.lifetime), findsOneWidget);
    expect(find.text(PaywallCopy.yoursForGood), findsOneWidget);
    expect(find.text(PaywallCopy.manageSubscription), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('Manage opens the store once', (tester) async {
    await openSettings(tester, annual);

    await tester.scrollAndTap(find.text(PaywallCopy.manageSubscription));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(store.manageCalls, 1);

    await tester.disposeApp();
  });

  testWidgets('Restore finding the purchase says so', (tester) async {
    await openSettings(tester, annual);
    store.restoreFinds = annual;

    await tapAndShowSnack(tester, PaywallCopy.restorePurchases);

    expect(store.restoreCalls, 1);
    expect(find.text(PaywallCopy.purchasesRestored), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('Restore failing says nothing was found', (tester) async {
    await openSettings(tester, annual);
    store.nextFailure = const StoreFailure();

    await tapAndShowSnack(tester, PaywallCopy.restorePurchases);

    expect(find.text(PaywallCopy.noPurchases), findsOneWidget);

    await tester.disposeApp();
  });
}
