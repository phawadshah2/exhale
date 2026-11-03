import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/set_habit_price.dart';
import 'package:exhale/features/habit/domain/usecases/update_habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/plan/presentation/widgets/limit_dial.dart';
import 'package:exhale/features/plan/presentation/widgets/plan_preview_card.dart';
import 'package:exhale/features/plan/presentation/widgets/quit_ruler.dart';
import 'package:exhale/features/plan/presentation/widgets/setup_chrome.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/pump_app.dart';

class _FailingUpdate implements UpdateHabit {
  @override
  Future<Result<void>> call(TrackedHabit habit) async =>
      const FailureResult<void>(StorageFailure());
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);
  final yesterday = today.addDays(-1);
  final running = PlanDraft(
    startDay: LogicalDay(2026, 10, 14),
    startLimit: 9,
    quitDay: LogicalDay(2026, 10, 14).addDays(63),
  );
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  setUp(() => setUpTestDependencies(FixedClock(now)));

  tearDown(InjectionContainer.reset);

  group('dropSentence', () {
    String sentence(int days, int limit) => dropSentence(
      ReductionPlan(
        startDay: today,
        startLimit: limit,
        quitDay: today.addDays(days),
      ),
    );

    test('a whole number of days', () {
      expect(sentence(63, 9), 'one fewer every 7 days');
    });

    test('a part number of days is rounded with about', () {
      expect(sentence(21, 4), 'one fewer about every 5 days');
    });

    test('under a day and a half', () {
      expect(sentence(14, 10), 'dropping about every day');
      expect(sentence(10, 10), 'dropping about every day');
    });

    test('steep', () {
      expect(sentence(5, 10), 'dropping fast');
    });
  });

  group('previewLimits', () {
    List<int?> limits(int days, int limit) => previewLimits(
      ReductionPlan(
        startDay: today,
        startLimit: limit,
        quitDay: today.addDays(days),
      ),
    );

    test('every stage, then 0', () {
      expect(limits(63, 9), [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
    });

    test('more than 10 rings shorten around a gap', () {
      expect(limits(280, 40), [40, 39, 38, 37, 36, null, 3, 2, 1, 0]);
    });

    test('11 rings is already more than 10', () {
      expect(limits(70, 10), [10, 9, 8, 7, 6, null, 3, 2, 1, 0]);
    });
  });

  Future<void> openEditPlan(
    WidgetTester tester, {
    PlanDraft? plan,
    Habit habit = Habit.smoking,
    int? priceCents,
    String? reason,
    List<Override> overrides = const [],
  }) async {
    await seedHabit(
      plan ?? running,
      habit: habit,
      priceCents: priceCents,
      reason: reason,
    );
    await tester.pumpAppPastSplash(height: 2400, overrides: overrides);
    await tester.tap(find.byTooltip('Edit plan'));
    await tester.pumpAndSettle();
  }

  // The save reads and writes drift, so real time has to pass between
  // fake-clock pumps.
  Future<void> settleStorage(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settleStorage(tester);
  }

  Future<PlanHistory> history(WidgetTester tester) async {
    final result = await tester.runAsync(
      () => sl<PlanRepository>().getHistory(1),
    );
    return (result! as Success<PlanHistory?>).value!;
  }

  Future<TrackedHabit> stored(WidgetTester tester) async {
    final habits = await tester.runAsync(
      () => sl<HabitRepository>().getActive(),
    );
    return (habits! as Success<List<TrackedHabit>>).value.single;
  }

  Future<void> enterPrice(WidgetTester tester, String price) async {
    await tester.enterText(find.byType(TextField).first, price);
    await tester.pump();
  }

  Finder dialIcon(IconData icon) =>
      find.descendant(of: find.byType(LimitDial), matching: find.byIcon(icon));

  Future<void> stepDial(WidgetTester tester, IconData icon) async {
    await tester.tap(dialIcon(icon));
    await tester.pump();
  }

  PrimaryButton footer(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  testWidgets('shows the frame N copy and cards', (tester) async {
    await openEditPlan(tester, priceCents: 900);

    expect(find.text('Edit plan'), findsOneWidget);
    expect(find.text('Turn it down. Not up.'), findsOneWidget);
    expect(
      find.text("It does go up. I'd just rather not watch."),
      findsOneWidget,
    );
    expect(find.text('Daily limit from today'), findsOneWidget);
    expect(find.text('Quit date'), findsOneWidget);
    expect(find.text('What that makes'), findsOneWidget);
    expect(find.text('Price of a pack'), findsOneWidget);
    expect(find.text('Your why'), findsOneWidget);
    expect(find.text('Change habit'), findsOneWidget);

    await tester.disposeApp();
  });

  group('footer', () {
    const caption = 'Past days keep their limits. Stages start again at 1.';

    testWidgets('nothing changed: disabled, with no caption', (tester) async {
      await openEditPlan(tester, priceCents: 900);

      expect(find.text('Shake on it again'), findsOneWidget);
      expect(footer(tester).onPressed, isNull);
      expect(find.text(caption), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('a plan change starts a new plan and goes back', (
      tester,
    ) async {
      await openEditPlan(tester);

      await stepDial(tester, AppIcons.remove);
      expect(find.text(caption), findsOneWidget);
      await press(tester, 'Shake on it again');

      final saved = await history(tester);
      expect(saved.plans, hasLength(2));
      expect(saved.limitOn(yesterday), 9);
      expect(saved.limitOn(today), 8);
      expect(saved.current.startDay, today);
      expect(find.byType(EditPlanPage), findsNothing);

      await tester.disposeApp();
    }, variant: ios);

    testWidgets('a price-only save reads Save price and keeps the plan', (
      tester,
    ) async {
      await openEditPlan(tester, priceCents: 900);

      await enterPrice(tester, '14.50');
      expect(find.text('Save price'), findsOneWidget);
      expect(find.text(caption), findsNothing);
      await press(tester, 'Save price');

      expect((await history(tester)).plans, hasLength(1));
      expect((await stored(tester)).priceCents, 1450);
      final points = await tester.runAsync(
        () => sl<HabitRepository>().watchPrices(1).first,
      );
      expect(
        points,
        contains(
          PricePoint(fromDay: today, priceCents: 1450, unitsPerContainer: 20),
        ),
      );
      expect(find.byType(EditPlanPage), findsNothing);

      await tester.disposeApp();
    }, variant: ios);

    testWidgets('both changed reads Shake on it again', (tester) async {
      await openEditPlan(tester, priceCents: 900);

      await enterPrice(tester, '14.50');
      await stepDial(tester, AppIcons.remove);

      expect(find.text('Shake on it again'), findsOneWidget);
      expect(find.text('Save price'), findsNothing);
      expect(find.text(caption), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('an invalid price shows the error and stays', (tester) async {
      await openEditPlan(tester, priceCents: 900);

      await enterPrice(tester, '1.2.3');
      expect(find.text('Enter a valid price'), findsOneWidget);
      await press(tester, 'Save price');

      expect(find.byType(EditPlanPage), findsOneWidget);
      expect((await stored(tester)).priceCents, 900);

      await tester.disposeApp();
    });
  });

  group('daily limit', () {
    testWidgets('the dial reads in the singular at 1', (tester) async {
      await openEditPlan(tester);

      expect(find.text('cigarettes a day'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        await stepDial(tester, AppIcons.remove);
      }

      expect(find.text('cigarette a day'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('no day window hides One every', (tester) async {
      await openEditPlan(tester);

      expect(find.textContaining('One every'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('a day window shows One every', (tester) async {
      final repository = sl<SettingsRepository>();
      final current = await repository.get() as Success<AppSettings>;
      await repository.save(
        current.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
      );
      await openEditPlan(tester);

      expect(find.text('One every 1 h 47 min'), findsOneWidget);

      await tester.disposeApp();
    });
  });

  group('quit date', () {
    final pastQuit = PlanDraft(
      startDay: today.addDays(-40),
      startLimit: 9,
      quitDay: today.addDays(-5),
    );

    testWidgets('shows the date and the chips', (tester) async {
      await openEditPlan(tester);

      expect(find.text('Dec 16'), findsOneWidget);
      expect(find.text('Keep current'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
      expect(find.text('8 weeks'), findsOneWidget);
      expect(find.text('16 weeks'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('Keep current is hidden past the quit date', (tester) async {
      await openEditPlan(tester, plan: pastQuit);

      expect(find.text('Keep current'), findsNothing);
      expect(find.text('Suggested'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a lower limit keeps the date and shows the new pace', (
      tester,
    ) async {
      await openEditPlan(tester);
      expect(find.textContaining('(was '), findsNothing);
      expect(find.textContaining('Use suggested date'), findsNothing);

      await stepDial(tester, AppIcons.remove);
      await tester.pumpAndSettle();

      expect(find.text('Dec 16'), findsOneWidget);
      expect(find.textContaining('Pace: '), findsOneWidget);
      expect(find.textContaining('(was '), findsOneWidget);
      expect(find.textContaining('Use suggested date ('), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('the suggested date follows the limit on one tap', (
      tester,
    ) async {
      await openEditPlan(tester);
      await stepDial(tester, AppIcons.remove);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Use suggested date ('));
      await tester.pumpAndSettle();

      expect(find.textContaining('Use suggested date'), findsNothing);
      expect(find.text('Dec 16'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('a chip sets the date', (tester) async {
      await openEditPlan(tester);

      await tester.tap(find.text('8 weeks'));
      await tester.pump();

      expect(find.text('Dec 11'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('dragging the ruler sets the date', (tester) async {
      await openEditPlan(tester);

      final ruler = tester.getRect(find.byType(QuitRuler));
      final drag = await tester.startGesture(
        ruler.centerLeft + const Offset(40, 0),
      );
      await tester.pump();
      await drag.moveTo(ruler.center);
      await tester.pump();
      await drag.up();
      await tester.pump();

      // The middle of 119 days.
      expect(find.text('Dec 15'), findsOneWidget);
      expect(find.text('Shake on it again'), findsOneWidget);
      expect(footer(tester).onPressed, isNotNull);

      await tester.disposeApp();
    });

    testWidgets('tapping the date opens the wheel', (tester) async {
      await openEditPlan(tester);

      await tester.tap(find.text('Dec 16'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoDatePicker), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('the steep warning shows', (tester) async {
      await openEditPlan(
        tester,
        plan: PlanDraft(
          startDay: today.addDays(-2),
          startLimit: 9,
          quitDay: today.addDays(3),
        ),
      );

      expect(
        find.text(
          "That's more than one fewer a day. A later date may feel easier.",
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });
  });

  group('what that makes', () {
    testWidgets('names the stages and the drop', (tester) async {
      await openEditPlan(
        tester,
        plan: PlanDraft(
          startDay: today,
          startLimit: 9,
          quitDay: today.addDays(63),
        ),
      );

      expect(find.text('9 stages · one fewer every 7 days'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('one stage reads in the singular', (tester) async {
      await openEditPlan(
        tester,
        plan: PlanDraft(
          startDay: today,
          startLimit: 1,
          quitDay: today.addDays(7),
        ),
      );

      expect(find.text('1 stage · one fewer every 7 days'), findsOneWidget);

      await tester.disposeApp();
    });
  });

  testWidgets('past the quit date a price alone reads Save price', (
    tester,
  ) async {
    await openEditPlan(
      tester,
      plan: PlanDraft(
        startDay: today.addDays(-40),
        startLimit: 9,
        quitDay: today.addDays(-5),
      ),
    );

    expect(find.text('Shake on it again'), findsOneWidget);
    expect(
      find.text('Past days keep their limits. Stages start again at 1.'),
      findsOneWidget,
    );

    await enterPrice(tester, '12');

    expect(find.text('Save price'), findsOneWidget);
    expect(
      find.text('Past days keep their limits. Stages start again at 1.'),
      findsNothing,
    );

    await press(tester, 'Save price');

    expect((await history(tester)).plans, hasLength(1));
    expect((await stored(tester)).priceCents, 1200);

    await tester.disposeApp();
  });

  group('price card', () {
    const fromToday =
        "Counts from today. What you've saved so far stays as it is.";
    const up = 'Up again? Almost like they want you to quit.';
    const down = "Cheaper? Don't celebrate with one.";

    testWidgets('a price added after clearing one counts from today', (
      tester,
    ) async {
      await seedHabit(running, priceCents: 1000);
      await sl<SetHabitPrice>()((
        habitId: 1,
        day: yesterday,
        priceCents: null,
        unitsPerContainer: 20,
      ));
      await tester.pumpAppPastSplash(height: 2400);
      await tester.tap(find.byTooltip('Edit plan'));
      await tester.pumpAndSettle();

      expect(find.text(fromToday), findsOneWidget);
      expect(find.text('Counts from Day 1.'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('is hidden for a habit with no cost', (tester) async {
      await openEditPlan(tester, habit: Habit.socialMedia);

      expect(find.textContaining('Price of'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('names one unit with no container, and has no stepper', (
      tester,
    ) async {
      await openEditPlan(tester, habit: Habit.caffeine);

      expect(find.text('Price of one cup'), findsOneWidget);
      expect(find.text('a pack'), findsNothing);
      expect(find.text('Counts from Day 1.'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('Was appears once the price differs', (tester) async {
      await openEditPlan(tester, priceCents: 800);

      expect(find.textContaining('Was'), findsNothing);
      expect(find.text(fromToday), findsOneWidget);

      await enterPrice(tester, '9');

      expect(find.text(r'Was $8.00'), findsOneWidget);

      await enterPrice(tester, '8');

      expect(find.textContaining('Was'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('tiles show once the price is valid', (tester) async {
      await openEditPlan(tester);

      expect(find.text('One cigarette'), findsNothing);

      await enterPrice(tester, '9');

      expect(find.text('One cigarette'), findsOneWidget);
      expect(find.text(r'$0.45'), findsOneWidget);
      expect(find.text('At your old 9 a day'), findsOneWidget);
      expect(find.text(r'$1,478 a year'), findsOneWidget);

      await enterPrice(tester, '1.2.3');

      expect(find.text('One cigarette'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('replies when the unit price goes up or down', (tester) async {
      await openEditPlan(tester, priceCents: 800);

      expect(find.text(up), findsNothing);

      await enterPrice(tester, '9');
      await tester.pumpAndSettle();
      expect(find.text(up), findsOneWidget);

      await enterPrice(tester, '7');
      await tester.pumpAndSettle();
      expect(find.text(down), findsOneWidget);

      await enterPrice(tester, '8');
      await tester.pumpAndSettle();
      expect(find.text(up), findsNothing);
      expect(find.text(down), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('fewer in a pack raises the unit price', (tester) async {
      await openEditPlan(tester, priceCents: 800);

      await tester.tap(find.bySemanticsLabel('Fewer cigarettes in a pack'));
      await tester.pumpAndSettle();

      expect(find.text('19'), findsOneWidget);
      expect(find.text(up), findsOneWidget);
      expect(find.text('Save price'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('no reply and Day 1 copy with no stored price', (tester) async {
      await openEditPlan(tester);

      await enterPrice(tester, '9');
      await tester.pumpAndSettle();

      expect(find.text(up), findsNothing);
      expect(find.text(down), findsNothing);
      expect(find.text('Counts from Day 1.'), findsOneWidget);
      expect(find.textContaining('Was'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets("I'd rather not know empties the field and hides itself", (
      tester,
    ) async {
      await openEditPlan(tester, priceCents: 800);

      await tester.tap(find.text("I'd rather not know"));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, isEmpty);
      expect(find.text("I'd rather not know"), findsNothing);
      expect(find.text(r'Was $8.00'), findsOneWidget);
      expect(find.text('Save price'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets("I'd rather not know is hidden with no price", (tester) async {
      await openEditPlan(tester);

      expect(find.text("I'd rather not know"), findsNothing);

      await tester.disposeApp();
    });
  });

  group('your why', () {
    Future<void> openWhy(WidgetTester tester) async {
      await tester.tap(find.text('Your why'));
      await tester.pumpAndSettle();
    }

    Finder whyField() => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );

    testWidgets('saves alone, with the form left as it was', (tester) async {
      await openEditPlan(tester, reason: 'For the kids');
      await stepDial(tester, AppIcons.remove);

      await openWhy(tester);
      expect(find.text('For the kids'), findsOneWidget);
      await tester.enterText(whyField(), 'For me');
      await tester.pump();
      await press(tester, 'Save');

      expect((await stored(tester)).reason, 'For me');
      expect((await history(tester)).plans, hasLength(1));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(EditPlanPage), findsOneWidget);
      expect(
        find.descendant(of: find.byType(LimitDial), matching: find.text('8')),
        findsOneWidget,
      );

      await tester.disposeApp();
    }, variant: ios);

    testWidgets('a failure keeps the sheet, its text and shows the error', (
      tester,
    ) async {
      await openEditPlan(
        tester,
        reason: 'For the kids',
        overrides: [updateHabitProvider.overrideWithValue(_FailingUpdate())],
      );

      await openWhy(tester);
      await tester.enterText(whyField(), 'For me');
      await tester.pump();
      await press(tester, 'Save');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('For me'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('save'),
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });
  });

  testWidgets('Add a price link opens Edit plan', (tester) async {
    await seedHabit(running);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.text('Add a price ›'));
    await tester.pumpAndSettle();

    expect(find.text('Daily limit from today'), findsOneWidget);
    expect(find.text('Price of a pack'), findsOneWidget);

    await tester.disposeApp();
  });

  group('at 200% text on an SE width', () {
    setUpAll(loadAppFonts);
    setUp(() {
      binding.platformDispatcher.textScaleFactorTestValue = 2;
    });
    tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);

    testWidgets('41 preview rings fit, and nothing overflows or clips', (
      tester,
    ) async {
      await openEditPlan(
        tester,
        plan: PlanDraft(
          startDay: today,
          startLimit: 40,
          quitDay: today.addDays(280),
        ),
        priceCents: 800,
      );
      tester.view.physicalSize = const Size(320 * 3, 2400 * 3);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final clipped = tester.clippedTexts(within: find.byType(EditPlanPage));
      await tester.disposeApp();
      expect(clipped, isEmpty);
    });

    testWidgets('the last buttons scroll clear of the footer and caption', (
      tester,
    ) async {
      await openEditPlan(tester, priceCents: 800);
      await stepDial(tester, AppIcons.remove);
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();
      }

      expect(
        tester
            .getBottomLeft(find.widgetWithText(OutlinedButton, 'Change habit'))
            .dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(SetupFooter)).dy),
      );

      await tester.disposeApp();
    });
  });
}
