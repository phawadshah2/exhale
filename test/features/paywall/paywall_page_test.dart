import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/presentation/pages/paywall_page.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/widgets/paywall_steps.dart';
import 'package:exhale/features/paywall/presentation/widgets/plan_card.dart';
import 'package:exhale/features/paywall/presentation/widgets/what_you_get.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 13, 15);
  final started = LogicalDay(2026, 11, 1);
  late FakeStoreRepository store;

  setUp(() async {
    store = FakeStoreRepository(now: () => now);
    await setUpTestDependencies(FixedClock(now), store: store);
  });

  tearDown(InjectionContainer.reset);

  /// Vaping at 12 a day, a pod at 15.00 for 20 sessions (75 cents each).
  /// With a log the gate opens the paywall; without one, welcome back.
  Future<void> seed({int? priceCents = 1500, bool withLog = true}) async {
    final habitId = await seedHabit(
      PlanDraft(
        startDay: started,
        startLimit: 12,
        quitDay: started.addDays(60),
      ),
      habit: Habit.vaping,
      priceCents: priceCents,
    );
    if (!withLog) return;
    final result = await sl<HabitLogRepository>().addLog(
      habitId: habitId,
      loggedAt: now.subtract(const Duration(days: 2)),
    );
    expect(result, isA<Success<Object>>());
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  /// Opens the paywall through the gate on a phone of [width] × [height]
  /// with its safe areas.
  Future<void> open(
    WidgetTester tester, {
    double width = 393,
    double height = 852,
    EdgeInsets insets = const EdgeInsets.only(top: 59, bottom: 34),
  }) async {
    tester.view.padding = FakeViewPadding(
      top: insets.top * 3,
      bottom: insets.bottom * 3,
    );
    await tester.pumpAppPastSplash(width: width, height: height);
    await settle(tester);
    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
  }

  Finder card(PlanKind plan) => find.byKey(PlanCard.keyFor(plan));

  Finder button(String label) =>
      find.widgetWithText(FilledButton, label).hitTestable();

  List<String> textsIn(Finder finder) => [
    for (final text
        in find
            .descendant(of: finder, matching: find.byType(Text))
            .evaluate()
            .map((e) => e.widget as Text))
      text.data ?? '',
  ];

  ScrollPosition pageScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(PaywallPage.pageKey),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  testWidgets('opens on Annual with its copy', (tester) async {
    await seed();
    await open(tester);

    expect(find.text(PaywallCopy.headlineTrial), findsOneWidget);
    expect(find.text('4 days'), findsOneWidget);
    expect(
      find.text('of pods costs more than a year of Exhale.'),
      findsOneWidget,
    );
    expect(find.text(PaywallCopy.statLabel), findsOneWidget);
    expect(find.text('Everything opens. Your plan starts.'), findsOneWidget);
    expect(find.text(r'Your year starts: $34.99.'), findsOneWidget);
    expect(find.text(PaywallCopy.trialTag), findsOneWidget);
    expect(button(PaywallCopy.startFreeWeek), findsOneWidget);
    expect(find.byKey(PaywallSteps.columnKey), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('another plan changes the stat, steps and button, not the '
      'cards', (tester) async {
    await seed();
    await open(tester);
    final cards = {
      for (final plan in PlanKind.values) plan: textsIn(card(plan)),
    };

    await tester.scrollAndTap(card(PlanKind.monthly));
    await tester.pumpAndSettle();

    expect(find.text('1 day'), findsOneWidget);
    expect(
      find.text('of pods costs more than a month of Exhale.'),
      findsOneWidget,
    );
    expect(find.text(r'Renews at $7.99 until you cancel.'), findsOneWidget);
    expect(button(PaywallCopy.subscribe), findsOneWidget);

    await tester.scrollAndTap(card(PlanKind.lifetime));
    await tester.pumpAndSettle();

    expect(find.text('7 days'), findsOneWidget);
    expect(
      find.text('of pods costs more than Exhale for good.'),
      findsOneWidget,
    );
    expect(find.text('Staying at zero is included.'), findsOneWidget);
    expect(button(PaywallCopy.buyOnce), findsOneWidget);
    for (final plan in PlanKind.values) {
      expect(textsIn(card(plan)), cards[plan]);
    }

    await tester.disposeApp();
  });

  testWidgets('trial already used: no tag, Starting headline, Subscribe', (
    tester,
  ) async {
    store.offers = [
      for (final offer in FakeStoreRepository.defaultOffers)
        if (offer.plan == PlanKind.annual)
          Offer(
            plan: offer.plan,
            displayPrice: offer.displayPrice,
            price: offer.price,
            currencyCode: offer.currencyCode,
            currencySymbol: offer.currencySymbol,
            trialEligible: false,
          )
        else
          offer,
    ];
    await seed();
    await open(tester);

    expect(find.text(PaywallCopy.headlineNoTrial), findsOneWidget);
    expect(find.text(PaywallCopy.trialTag), findsNothing);
    expect(find.text(PaywallCopy.eachYear), findsOneWidget);
    expect(button(PaywallCopy.subscribe), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('no price: steps down the page, plain lines, no stat', (
    tester,
  ) async {
    await seed(priceCents: null);
    await open(tester);

    expect(find.text(PaywallCopy.whatYouGet), findsOneWidget);
    expect(find.text('Go from 12 a day to 0'), findsOneWidget);
    expect(find.text('Extra time when it gets hard'), findsOneWidget);
    expect(find.text('Your data stays private'), findsOneWidget);
    for (final tail in ['to 0', '7 days', 'Zero']) {
      expect(find.text(tail), findsNothing);
    }
    expect(find.text(PaywallCopy.statLabel), findsNothing);
    expect(find.byKey(PaywallSteps.columnKey), findsOneWidget);
    expect(find.byKey(PaywallSteps.rowKey), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('offline: the card and a disabled Continue; Try again loads '
      'the offers', (tester) async {
    store.offline = true;
    await seed();
    await open(tester);

    expect(find.text(PaywallCopy.unreachableTitle), findsOneWidget);
    expect(find.text(PaywallCopy.whatYouGet), findsOneWidget);
    expect(card(PlanKind.annual), findsNothing);
    // The card follows straight on; spare height sits above the button.
    expect(
      tester.getRect(find.byKey(PaywallPage.plansKey)).top -
          tester.getRect(find.byType(WhatYouGet)).bottom,
      PaywallPage.minGap + 4,
    );
    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, PaywallCopy.continueLabel),
    );
    expect(continueButton.onPressed, isNull);

    store.offline = false;
    await tester.tap(find.text(PaywallCopy.tryAgain));
    await settle(tester);

    expect(find.text(PaywallCopy.unreachableTitle), findsNothing);
    expect(card(PlanKind.annual), findsOneWidget);
    expect(button(PaywallCopy.startFreeWeek), findsOneWidget);

    await tester.disposeApp();
  });

  group('purchase', () {
    testWidgets('purchased opens Home', (tester) async {
      await seed();
      await open(tester);

      await tester.tap(button(PaywallCopy.startFreeWeek));
      await settle(tester);

      expect(store.purchaseCalls, 1);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(PaywallPage.pageKey), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('cancelled stays, silent', (tester) async {
      store.nextOutcome = PurchaseOutcome.cancelled;
      await seed();
      await open(tester);

      await tester.tap(button(PaywallCopy.startFreeWeek));
      await settle(tester);

      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('pending says Waiting for approval', (tester) async {
      store.nextOutcome = PurchaseOutcome.pending;
      await seed();
      await open(tester);

      await tester.tap(button(PaywallCopy.startFreeWeek));
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(PaywallCopy.waitingApproval), findsOneWidget);
      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a failure says so', (tester) async {
      store.nextFailure = const StoreFailure();
      await seed();
      await open(tester);

      await tester.tap(button(PaywallCopy.startFreeWeek));
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(PaywallCopy.purchaseFailed), findsOneWidget);
      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a double tap buys once', (tester) async {
      final slow = _SlowStore(now: () => now);
      await InjectionContainer.reset();
      await setUpTestDependencies(FixedClock(now), store: slow);
      await seed();
      await open(tester);

      final finder = button(PaywallCopy.startFreeWeek);
      await tester.tap(finder);
      await tester.tap(finder, warnIfMissed: false);
      slow.sheet.complete(const Success(PurchaseOutcome.cancelled));
      await settle(tester);

      expect(slow.purchaseCalls, 1);

      await tester.disposeApp();
    });
  });

  group('restore', () {
    testWidgets('a purchase found opens Home', (tester) async {
      store.restoreFinds = const Entitled(
        plan: PlanKind.lifetime,
        expiresAt: null,
        inTrial: false,
      );
      await seed();
      await open(tester);

      await tester.tap(find.text(PaywallCopy.restore));
      await settle(tester);

      expect(store.restoreCalls, 1);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('nothing found says so', (tester) async {
      await seed();
      await open(tester);

      await tester.tap(find.text(PaywallCopy.restore));
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(PaywallCopy.noPurchases), findsOneWidget);
      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);

      await tester.disposeApp();
    });
  });

  testWidgets('no back chevron when the gate opens it', (tester) async {
    await seed();
    await open(tester);

    expect(find.byIcon(AppIcons.back), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('a back chevron when pushed from the reveal', (tester) async {
    await seed(withLog: false);
    reduceMotion(tester);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(planButton().hitTestable());
    await settle(tester);

    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(PaywallPage.pageKey),
        matching: find.byIcon(AppIcons.back),
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  group('fit', () {
    setUp(loadAppFonts);

    testWidgets('the button sits where the reveal has its button', (
      tester,
    ) async {
      await seed(withLog: false);
      reduceMotion(tester);
      tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
      await tester.pumpAppPastSplash(width: 393, height: 852);
      final reveal = tester.getRect(planButton().hitTestable());
      expect(reveal.bottom, 852 - 34 - 8 - 14);

      await tester.tap(planButton().hitTestable());
      await settle(tester);

      final paywall = tester.getRect(button(PaywallCopy.startFreeWeek));
      expect(paywall.top, reveal.top);
      expect(paywall.bottom, reveal.bottom);
      final terms = find.widgetWithText(TextButton, PaywallCopy.terms);
      expect(tester.getSize(terms).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(terms).bottom, lessThanOrEqualTo(852));

      await tester.disposeApp();
    });

    testWidgets('nothing scrolls on a regular iPhone', (tester) async {
      await seed();
      await open(tester);

      expect(pageScroll(tester).maxScrollExtent, 0);
      expect(find.byKey(PaywallSteps.columnKey), findsOneWidget);
      expect(
        tester.clippedTexts(within: find.byKey(PaywallPage.pageKey)),
        isEmpty,
      );

      await tester.disposeApp();
    });

    testWidgets('nothing scrolls on a small iPhone, with the icon row', (
      tester,
    ) async {
      await seed();
      await open(
        tester,
        width: 375,
        height: 667,
        insets: const EdgeInsets.only(top: 20),
      );

      expect(pageScroll(tester).maxScrollExtent, 0);
      expect(find.byKey(PaywallSteps.rowKey), findsOneWidget);
      expect(
        tester.clippedTexts(within: find.byKey(PaywallPage.pageKey)),
        isEmpty,
      );

      await tester.disposeApp();
    });

    testWidgets('no price on a small iPhone fits, with two lines', (
      tester,
    ) async {
      await seed(priceCents: null);
      await open(
        tester,
        width: 375,
        height: 667,
        insets: const EdgeInsets.only(top: 20),
      );

      expect(pageScroll(tester).maxScrollExtent, 0);
      expect(find.byKey(PaywallSteps.rowKey), findsOneWidget);
      expect(find.text(PaywallCopy.moreTime), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('with a stat on the largest iPhone the plans follow on', (
      tester,
    ) async {
      await seed();
      await open(
        tester,
        width: 440,
        height: 956,
        insets: const EdgeInsets.only(top: 62, bottom: 34),
      );

      expect(pageScroll(tester).maxScrollExtent, 0);
      final steps = tester.getRect(find.byKey(PaywallSteps.columnKey));
      final plans = tester.getRect(find.byKey(PaywallPage.plansKey));
      expect(plans.top - steps.bottom, PaywallPage.minGap + 4);

      await tester.disposeApp();
    });

    for (final (name, width, height, insets) in [
      ('a regular', 393.0, 852.0, const EdgeInsets.only(top: 59, bottom: 34)),
      ('the largest', 440.0, 956.0, const EdgeInsets.only(top: 62, bottom: 34)),
    ]) {
      testWidgets('no price on $name iPhone flows from the top', (
        tester,
      ) async {
        await seed(priceCents: null);
        await open(tester, width: width, height: height, insets: insets);

        expect(pageScroll(tester).maxScrollExtent, 0);
        expect(
          tester.clippedTexts(within: find.byKey(PaywallPage.pageKey)),
          isEmpty,
        );
        final title = find.text(PaywallCopy.headlineTrial);
        expect(
          tester.widget<Text>(title).style?.fontSize,
          PaywallPage.headlineSize,
        );
        final headline = tester.getRect(title);
        final steps = tester.getRect(find.byKey(PaywallSteps.columnKey));
        final what = tester.getRect(find.byType(WhatYouGet));
        final plans = tester.getRect(find.byKey(PaywallPage.plansKey));
        expect(steps.top - headline.bottom, PaywallPage.minGap);
        expect(what.top - steps.bottom, PaywallPage.minGap + 4);
        expect(plans.top - what.bottom, PaywallPage.minGap + 4);
        // Spare height sits above the button, not between the blocks.
        final buttonTop = tester.getRect(button(PaywallCopy.startFreeWeek)).top;
        expect(
          buttonTop - plans.bottom,
          greaterThanOrEqualTo(AppSpacing.gutterSm),
        );

        await tester.disposeApp();
      });
    }

    testWidgets('at 200% text the page scrolls and the button stays', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await seed();
      await open(tester);

      expect(pageScroll(tester).maxScrollExtent, greaterThan(0));
      final rect = tester.getRect(
        find.widgetWithText(FilledButton, PaywallCopy.startFreeWeek),
      );
      expect(rect.bottom, lessThanOrEqualTo(852 - 34));
      expect(rect.top, greaterThan(0));

      await tester.disposeApp();
    });
  });

  testWidgets('each card is 44 pt tall and reads its plan', (tester) async {
    final semantics = tester.ensureSemantics();
    await seed();
    await open(tester);

    for (final plan in PlanKind.values) {
      expect(tester.getSize(card(plan)).height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.getSemantics(card(PlanKind.annual)),
      isSemantics(
        label:
            r'Annual, Your plan + a year at zero, $34.99 per year, '
            '7 days free',
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(card(PlanKind.monthly)),
      isSemantics(
        label: r'Monthly, No trial. Cancel any time, $7.99 per month',
        isChecked: false,
      ),
    );

    semantics.dispose();
    await tester.disposeApp();
  });

  testWidgets('Reduce Motion shows everything at once', (tester) async {
    await seed(withLog: false);
    reduceMotion(tester);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(planButton().hitTestable());
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 20));
      if (card(PlanKind.lifetime).evaluate().isNotEmpty) break;
    }
    await tester.pump();

    final opacities = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byKey(PaywallPage.pageKey),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacities, isNotEmpty);
    expect(opacities.map((o) => o.opacity), everyElement(1.0));

    await tester.disposeApp();
  });
}

/// A purchase sheet that stays up until [sheet] completes.
class _SlowStore extends FakeStoreRepository {
  _SlowStore({super.now});

  final sheet = Completer<Result<PurchaseOutcome>>();

  @override
  Future<Result<PurchaseOutcome>> purchase(PlanKind plan) {
    purchaseCalls++;
    return sheet.future;
  }
}
