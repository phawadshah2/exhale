import 'dart:async';

import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/renewing_subscription.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:exhale/features/settings/presentation/widgets/subscription_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 19, 9);
  late FakeStoreRepository store;

  final annual = Entitled(
    plan: PlanKind.annual,
    expiresAt: DateTime(2027, 11, 19, 9),
    inTrial: false,
  );
  final monthly = Entitled(
    plan: PlanKind.monthly,
    expiresAt: DateTime(2026, 12, 3, 9),
    inTrial: false,
  );
  final trial = Entitled(
    plan: PlanKind.annual,
    expiresAt: DateTime(2026, 11, 21, 9),
    inTrial: true,
  );
  const lifetime = Entitled(
    plan: PlanKind.lifetime,
    expiresAt: null,
    inTrial: false,
  );

  tearDown(InjectionContainer.reset);

  Future<void> openSheet(
    WidgetTester tester,
    Access access, {
    RenewingSubscription? renewing,
    bool offline = false,
    bool renewingFails = false,
    bool autoRenew = true,
  }) async {
    store =
        FakeStoreRepository(
            access: access,
            renewing: renewing,
            offline: offline,
            now: () => now,
          )
          ..renewingFails = renewingFails
          ..autoRenew = autoRenew;
    await setUpTestDependencies(FixedClock(now), store: store);
    tester.view
      ..physicalSize = const Size(390 * 3, 1600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await startupOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => unawaited(showSubscriptionSheet(context)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    await tester.scrollAndTap(find.text(label));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder row(String label) => find.widgetWithText(SettingsRow, label);

  testWidgets('annual shows change plan and billing', (tester) async {
    await openSheet(tester, annual);

    expect(find.text(PaywallCopy.subscriptionSheetTitle), findsOneWidget);
    expect(find.text('Exhale Annual'), findsOneWidget);
    expect(find.text(r'$34.99 a year · renews Nov 19'), findsOneWidget);
    expect(find.text(PaywallCopy.active), findsOneWidget);
    expect(find.text(PaywallCopy.changePlan.toUpperCase()), findsOneWidget);
    expect(find.text(PaywallCopy.payMonthly), findsOneWidget);
    expect(find.text(r'$7.99 a month'), findsOneWidget);
    expect(find.text(PaywallCopy.goLifetime), findsOneWidget);
    expect(find.text(r'$59.99 once'), findsOneWidget);
    expect(find.text(PaywallCopy.billing.toUpperCase()), findsOneWidget);
    for (final label in [
      PaywallCopy.manageInAppStore,
      PaywallCopy.restorePurchases,
      PaywallCopy.redeemCode,
      PaywallCopy.requestRefund,
    ]) {
      expect(row(label), findsOneWidget);
    }
    expect(
      find.text(PaywallCopy.cancelAnyTime('Annual', 'Nov 19')),
      findsOneWidget,
    );

    await tapRow(tester, PaywallCopy.payMonthly);
    expect(store.manageCalls, 1);
    await tester.disposeApp();
  });

  testWidgets('monthly offers Pay yearly', (tester) async {
    await openSheet(tester, monthly);

    expect(find.text('Exhale Monthly'), findsOneWidget);
    expect(find.text(PaywallCopy.payYearly), findsOneWidget);
    expect(find.text(r'$34.99 a year'), findsOneWidget);
    expect(find.text(PaywallCopy.payMonthly), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('trial shows days left and Cancel free week', (tester) async {
    await openSheet(tester, trial);

    expect(find.text(PaywallCopy.freeWeek), findsOneWidget);
    expect(find.text('2 days left'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.text(PaywallCopy.trialStarts('Nov 21', r'$34.99')),
      findsOneWidget,
    );
    expect(find.text(PaywallCopy.afterFreeWeek.toUpperCase()), findsOneWidget);
    expect(find.text(PaywallCopy.payMonthlyInstead), findsOneWidget);
    expect(find.text(PaywallCopy.goLifetime), findsOneWidget);
    expect(find.text(PaywallCopy.cancelBefore('Nov 21')), findsOneWidget);

    await tapRow(tester, PaywallCopy.cancelFreeWeek);
    expect(store.manageCalls, 1);
    await tester.disposeApp();
  });

  testWidgets('trial has no refund row', (tester) async {
    await openSheet(tester, trial);
    expect(find.text(PaywallCopy.requestRefund), findsNothing);
    expect(find.text(PaywallCopy.manageInAppStore), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('lifetime has no change plan', (tester) async {
    await openSheet(tester, lifetime);

    expect(find.text(PaywallCopy.lifetimeTitle), findsOneWidget);
    expect(find.text(PaywallCopy.yoursForGood), findsOneWidget);
    expect(find.text(PaywallCopy.changePlan.toUpperCase()), findsNothing);
    expect(find.text(PaywallCopy.goLifetime), findsNothing);
    expect(find.text(PaywallCopy.manageInAppStore), findsNothing);
    expect(row(PaywallCopy.restorePurchases), findsOneWidget);
    expect(row(PaywallCopy.redeemCode), findsOneWidget);
    expect(row(PaywallCopy.requestRefund), findsOneWidget);
    expect(find.textContaining('still renews'), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('the sheet is only as tall as its content', (tester) async {
    await openSheet(tester, lifetime);

    final sheet = tester.getRect(find.byType(AppSheetFrame));
    final lastRow = tester.getRect(row(PaywallCopy.requestRefund));
    expect(sheet.bottom - lastRow.bottom, lessThan(80));
    await tester.disposeApp();
  });

  testWidgets('lifetime with a renewing Annual shows the note and Cancel '
      'Annual', (tester) async {
    await openSheet(
      tester,
      lifetime,
      renewing: RenewingSubscription(
        plan: PlanKind.annual,
        renewsAt: DateTime(2026, 12, 3, 9),
      ),
    );

    expect(
      find.text(PaywallCopy.stillRenews('Annual', 'Dec 3')),
      findsOneWidget,
    );
    await tapRow(tester, PaywallCopy.cancelPlan('Annual'));
    expect(store.manageCalls, 1);
    await tester.disposeApp();
  });

  testWidgets('a failed renewal check shows no note', (tester) async {
    await openSheet(tester, lifetime, renewingFails: true);
    expect(find.textContaining('still renews'), findsNothing);
    expect(find.text(PaywallCopy.lifetimeTitle), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('unknown offers only Restore and Redeem', (tester) async {
    await openSheet(tester, const AccessUnknown(), offline: true);

    expect(find.text(PaywallCopy.cantReachStore), findsOneWidget);
    expect(find.byType(SettingsRow), findsNWidgets(2));
    expect(row(PaywallCopy.restorePurchases), findsOneWidget);
    expect(row(PaywallCopy.redeemCode), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('restore shows a spinner while busy', (tester) async {
    await openSheet(tester, annual);
    final gate = store.restoreGate = Completer<void>();

    await tapRow(tester, PaywallCopy.restorePurchases);
    expect(
      find.descendant(
        of: row(PaywallCopy.restorePurchases),
        matching: find.byType(CupertinoActivityIndicator),
      ),
      findsOneWidget,
    );

    gate.complete();
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.text(PaywallCopy.purchasesRestored), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('actions are disabled while busy', (tester) async {
    await openSheet(tester, annual);
    final gate = store.restoreGate = Completer<void>();

    await tapRow(tester, PaywallCopy.restorePurchases);
    await tester.tap(find.text(PaywallCopy.goLifetime));
    await tester.tap(find.text(PaywallCopy.manageInAppStore));
    await tester.tap(find.text(PaywallCopy.restorePurchases));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(store.purchaseCalls, 0);
    expect(store.manageCalls, 0);
    expect(store.restoreCalls, 1);

    gate.complete();
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    await tester.disposeApp();
  });

  testWidgets('Go Lifetime buys Lifetime and says so', (tester) async {
    await openSheet(tester, annual);

    await tapRow(tester, PaywallCopy.goLifetime);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(store.purchaseCalls, 1);
    expect(store.access, lifetime);
    expect(find.text(PaywallCopy.lifetimeBought), findsOneWidget);
    expect(find.text(PaywallCopy.lifetimeTitle), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Redeem a code calls the store', (tester) async {
    await openSheet(tester, annual);
    await tapRow(tester, PaywallCopy.redeemCode);
    expect(store.redeemCalls, 1);
    await tester.disposeApp();
  });

  group('auto-renew', () {
    testWidgets('a cancelled Annual says when it ends, not Active', (
      tester,
    ) async {
      await openSheet(tester, annual, autoRenew: false);

      expect(find.text(r'$34.99 a year · ends Nov 19'), findsOneWidget);
      expect(find.text(PaywallCopy.active), findsNothing);
      expect(
        find.text(PaywallCopy.cancelAnyTime('Annual', 'Nov 19')),
        findsNothing,
      );
      expect(row(PaywallCopy.manageInAppStore), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('an unchecked renewal says paid until', (tester) async {
      await openSheet(tester, annual, renewingFails: true);

      expect(find.text(r'$34.99 a year · paid until Nov 19'), findsOneWidget);
      expect(find.text(PaywallCopy.active), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('a cancelled free week has no charge lines', (tester) async {
      await openSheet(tester, trial, autoRenew: false);

      expect(find.text(PaywallCopy.freeWeekEnds('Nov 21')), findsOneWidget);
      expect(
        find.text(PaywallCopy.trialStarts('Nov 21', r'$34.99')),
        findsNothing,
      );
      expect(find.text(PaywallCopy.cancelBefore('Nov 21')), findsNothing);
      expect(find.text(PaywallCopy.cancelFreeWeek), findsNothing);
      expect(row(PaywallCopy.manageInAppStore), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('an unchecked free week says free until', (tester) async {
      await openSheet(tester, trial, renewingFails: true);

      expect(find.text(PaywallCopy.freeUntil('Nov 21')), findsOneWidget);
      expect(
        find.text(PaywallCopy.trialStarts('Nov 21', r'$34.99')),
        findsNothing,
      );
      await tester.disposeApp();
    });

    testWidgets('the note goes once Cancel Annual returns', (tester) async {
      await openSheet(
        tester,
        lifetime,
        renewing: RenewingSubscription(
          plan: PlanKind.annual,
          renewsAt: DateTime(2026, 12, 3, 9),
        ),
      );

      store.renewing = null;
      await tapRow(tester, PaywallCopy.cancelPlan('Annual'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.textContaining('still renews'), findsNothing);
      await tester.disposeApp();
    });
  });

  testWidgets('a free week ending today says Ends today', (tester) async {
    await openSheet(
      tester,
      Entitled(
        plan: PlanKind.annual,
        expiresAt: DateTime(2026, 11, 19, 22),
        inTrial: true,
      ),
    );
    expect(find.text('Ends today'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a failed restore says the store is unreachable', (tester) async {
    await openSheet(tester, annual);
    store.nextFailure = const StoreFailure();

    await tapRow(tester, PaywallCopy.restorePurchases);

    expect(find.text(PaywallCopy.cantReachStore), findsOneWidget);
    expect(find.text(PaywallCopy.noPurchases), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('a double tap opens the App Store sheet once', (tester) async {
    await openSheet(tester, annual);
    final gate = store.sheetGate = Completer<void>();

    await tapRow(tester, PaywallCopy.manageInAppStore);
    await tester.tap(find.text(PaywallCopy.manageInAppStore));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(store.manageCalls, 1);
    gate.complete();
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    await tester.disposeApp();
  });

  testWidgets('Request a refund passes the current plan', (tester) async {
    await openSheet(tester, monthly);
    await tapRow(tester, PaywallCopy.requestRefund);
    expect(store.refundRequests, [PlanKind.monthly]);
    await tester.disposeApp();
  });
}
