import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/home/presentation/widgets/stage_cards.dart';
import 'package:exhale/features/home/presentation/widgets/stage_choice_sheet.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/services/plan_choices.dart';
import 'package:exhale/features/plan/domain/usecases/answer_stage_check.dart';
import 'package:exhale/features/plan/presentation/providers/plan_report_provider.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/pump_app.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);

/// Delegates to [inner]; [answer] can be made to fail or wait.
class _SpyChecks implements StageCheckRepository {
  _SpyChecks(this.inner);
  final StageCheckRepository inner;
  int answers = 0;
  bool failAnswer = false;
  Completer<void>? gate;

  @override
  Stream<List<StageCheck>> watchChecks(int habitId) =>
      inner.watchChecks(habitId);

  @override
  Future<Result<List<StageCheck>>> getChecks(int habitId) =>
      inner.getChecks(habitId);

  @override
  Future<Result<void>> record(
    int habitId,
    StageCheck check, {
    PlanHold? hold,
    LogicalDay? closesHoldWindow,
  }) => inner.record(
    habitId,
    check,
    hold: hold,
    closesHoldWindow: closesHoldWindow,
  );

  @override
  Future<Result<void>> answer(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    DateTime at,
  ) async {
    answers++;
    await gate?.future;
    return failAnswer
        ? const FailureResult<void>(StorageFailure())
        : await inner.answer(habitId, planStartDay, windowEndDay, at);
  }

  @override
  Future<Result<void>> keepOriginalDate(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    LogicalDay holdStart,
    DateTime at,
  ) => inner.keepOriginalDate(
    habitId,
    planStartDay,
    windowEndDay,
    holdStart,
    at,
  );
}

void main() {
  late int habitId;
  late _SpyChecks spy;

  /// 12 a day from Oct 12, quit Jan 4: stage 4 (9 a day) is Nov 2 to 8.
  final weekly = PlanDraft(
    startDay: _oct(12),
    startLimit: 12,
    quitDay: LogicalDay(2027, 1, 4),
  );
  final nov9 = DateTime(2026, 11, 9, 15, 42);

  tearDown(InjectionContainer.reset);

  Future<void> start({Habit habit = Habit.smoking, int? priceCents}) async {
    await setUpTestDependencies(FixedClock(nov9));
    habitId = await seedHabit(weekly, habit: habit, priceCents: priceCents);
    spy = _SpyChecks(sl<StageCheckRepository>());
    sl
      ..unregister<AnswerStageCheck>()
      ..registerFactory(() => AnswerStageCheck(spy, sl<Clock>()));
  }

  Future<void> logDay(LogicalDay day, int count, {Trigger? trigger}) async {
    for (var i = 0; i < count; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: habitId,
          loggedAt: DateTime(day.year, day.month, day.day, 12, i),
          trigger: trigger,
        ),
      );
    }
  }

  /// 11 a day for the 14 days ending Nov 8: 154 logged, 133 allowed.
  /// Five tagged stress, three coffee, two boredom and one social.
  Future<void> logFortnight() async {
    for (var d = 26; d <= 31; d++) {
      await logDay(_oct(d), 11);
    }
    for (var d = 1; d <= 8; d++) {
      await logDay(_nov(d), 11);
    }
  }

  Future<void> record(StageOutcome outcome) async {
    await sl<StageCheckRepository>().record(
      habitId,
      StageCheck(
        planStartDay: _oct(12),
        windowEndDay: _nov(8),
        checkDay: _nov(9),
        outcome: outcome,
      ),
    );
  }

  Future<void> pumpHome(WidgetTester tester) =>
      tester.pumpAppPastSplash(height: 2400);

  Future<void> openSheet(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  Future<PlanHistory> history(WidgetTester tester) async {
    final result = await tester.runAsync(
      () => sl<PlanRepository>().getHistory(habitId),
    );
    return (result! as Success<PlanHistory?>).value!;
  }

  Future<StageCheck> onlyCheck(WidgetTester tester) async {
    final result = await tester.runAsync(
      () => sl<StageCheckRepository>().getChecks(habitId),
    );
    return (result! as Success<List<StageCheck>>).value.single;
  }

  Future<void> seedReview(
    WidgetTester tester, {
    bool triggers = true,
    Habit habit = Habit.smoking,
    int? priceCents,
  }) async {
    await tester.runAsync(() async {
      await start(habit: habit, priceCents: priceCents);
      if (triggers) {
        await logDay(_nov(8), 5, trigger: Trigger.stress);
        await logDay(_nov(7), 3, trigger: Trigger.coffee);
        await logDay(_nov(6), 2, trigger: Trigger.boredom);
        await logDay(_nov(5), 1, trigger: Trigger.social);
        // 11 a day on the other days of the fortnight, 154 in all.
        for (var d = 26; d <= 31; d++) {
          await logDay(_oct(d), 11);
        }
        for (var d = 1; d <= 8; d++) {
          final tagged = switch (d) {
            8 => 5,
            7 => 3,
            6 => 2,
            5 => 1,
            _ => 0,
          };
          await logDay(_nov(d), 11 - tagged);
        }
      } else {
        await logFortnight();
      }
      await record(StageOutcome.review);
    });
    await pumpHome(tester);
  }

  group('choice words', () {
    PlanChoice choice(
      ChoiceKind kind, {
      int limit = 9,
      double pace = 7,
      int change = 0,
    }) => PlanChoice(
      kind: kind,
      limit: limit,
      quitDay: _nov(20),
      daysPerDrop: pace,
      changeDays: change,
    );

    test('names', () {
      expect(
        StageChoiceCopy.name(choice(ChoiceKind.realNumber)),
        'Start from your real number',
      );
      expect(StageChoiceCopy.name(choice(ChoiceKind.slowDown)), 'Slow down');
      expect(StageChoiceCopy.name(choice(ChoiceKind.keep)), 'Keep my plan');
      expect(
        StageChoiceCopy.name(choice(ChoiceKind.startAgain, limit: 12)),
        'Start again from 12',
      );
    });

    test('detail lines', () {
      expect(
        StageChoiceCopy.detail(choice(ChoiceKind.slowDown, pace: 14)),
        '9 a day, one fewer every 14 days',
      );
      expect(
        StageChoiceCopy.detail(choice(ChoiceKind.keep, limit: 8)),
        '8 today, one fewer every 7 days',
      );
      expect(
        StageChoiceCopy.detail(choice(ChoiceKind.realNumber, pace: 1.4)),
        '9 a day, dropping about every day',
      );
      expect(
        StageChoiceCopy.detail(choice(ChoiceKind.realNumber, pace: 1.5)),
        '9 a day, one fewer every 2 days',
      );
    });

    test('change labels', () {
      expect(StageChoiceCopy.change(choice(ChoiceKind.keep)), 'No change');
      expect(
        StageChoiceCopy.change(choice(ChoiceKind.keep, change: 21)),
        '3 weeks later',
      );
      expect(
        StageChoiceCopy.change(choice(ChoiceKind.keep, change: 7)),
        '1 week later',
      );
      expect(
        StageChoiceCopy.change(choice(ChoiceKind.keep, change: 10)),
        '10 days later',
      );
      expect(
        StageChoiceCopy.change(choice(ChoiceKind.keep, change: 1)),
        '1 day later',
      );
      expect(
        StageChoiceCopy.change(choice(ChoiceKind.keep, change: -14)),
        '2 weeks earlier',
      );
    });
  });

  group('review sheet', () {
    testWidgets('shows the fortnight, the triggers and three choices', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      expect(find.text("Let's look at the plan"), findsOneWidget);
      expect(find.text('Not a telling-off. Just the numbers.'), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
      expect(find.text('logged'), findsOneWidget);
      expect(find.text('133'), findsOneWidget);
      expect(find.text('allowed'), findsOneWidget);
      expect(find.text('About 11'), findsOneWidget);
      expect(find.text('What came up most'), findsOneWidget);
      expect(find.text('Stress · 5'), findsOneWidget);
      expect(find.text('Coffee · 3'), findsOneWidget);
      expect(find.text('Boredom · 2'), findsOneWidget);
      expect(find.textContaining('Social'), findsNothing);

      expect(find.text('Start from your real number'), findsOneWidget);
      expect(find.text('11 a day, one fewer every 7 days'), findsOneWidget);
      expect(find.text('Jan 25'), findsOneWidget);
      expect(find.text('3 weeks later'), findsOneWidget);
      expect(find.text('Slow down'), findsOneWidget);
      expect(find.text('9 a day, one fewer every 14 days'), findsOneWidget);
      expect(find.text('Mar 15'), findsOneWidget);
      expect(find.text('10 weeks later'), findsOneWidget);
      expect(find.text('Keep my plan'), findsOneWidget);
      expect(find.text('8 today, one fewer every 7 days'), findsOneWidget);
      expect(find.text('No change'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('counts the two failed weeks, not the held week', (
      tester,
    ) async {
      // Stage 2 (11 a day, Oct 19 to 25) failed and was held to Nov 1;
      // stage 3 (10 a day, Nov 2 to 8) failed too. The held week went well.
      await tester.runAsync(() async {
        await start();
        for (var d = 19; d <= 25; d++) {
          await logDay(_oct(d), 12, trigger: Trigger.stress);
        }
        for (var d = 26; d <= 31; d++) {
          await logDay(_oct(d), 8, trigger: Trigger.social);
        }
        await logDay(_nov(1), 8, trigger: Trigger.social);
        for (var d = 2; d <= 8; d++) {
          await logDay(_nov(d), 11);
        }
        final checks = sl<StageCheckRepository>();
        await checks.record(
          habitId,
          StageCheck(
            planStartDay: _oct(12),
            windowEndDay: _oct(25),
            checkDay: _oct(26),
            outcome: StageOutcome.hold,
          ),
          hold: PlanHold(startDay: _oct(26)),
        );
        await checks.answer(
          habitId,
          _oct(12),
          _oct(25),
          DateTime(2026, 10, 26, 9),
        );
        await record(StageOutcome.review);
      });
      await pumpHome(tester);
      await openSheet(tester, 'Review my plan');

      // 84 + 77 logged against 77 + 70; 161 over 14 days is about 12.
      expect(find.text('161'), findsOneWidget);
      expect(find.text('147'), findsOneWidget);
      expect(find.text('About 12'), findsOneWidget);
      expect(find.text('Stress · 84'), findsOneWidget);
      expect(find.textContaining('Social'), findsNothing);
      expect(find.text('12 a day, one fewer every 7 days'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('hides the triggers when none are tagged', (tester) async {
      await seedReview(tester, triggers: false);
      await openSheet(tester, 'Review my plan');

      expect(find.text("Let's look at the plan"), findsOneWidget);
      expect(find.text('What came up most'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('starts on the real number, and the button follows', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      expect(
        find.widgetWithText(FilledButton, 'Shake on it again'),
        findsOneWidget,
      );
      expect(
        find.text('Past days keep their limits. Stages start again at 1.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep my plan'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Keep my plan'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Shake on it again'),
        findsNothing,
      );
      expect(
        find.text("We'll look again if two more checks run over."),
        findsOneWidget,
      );

      await tester.tap(find.text('Slow down'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Shake on it again'),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets('a choice reads as one thing to VoiceOver', (tester) async {
      final handle = tester.ensureSemantics();
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      expect(
        find.bySemanticsLabel(
          'Slow down. 9 a day, one fewer every 14 days. Quit date Mar 15. '
          '10 weeks later.',
        ),
        findsOneWidget,
      );

      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('a new plan restarts the stages and clears the card', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      await tester.tap(find.widgetWithText(FilledButton, 'Shake on it again'));
      await tester.pumpAndSettle();

      expect(find.text("Let's look at the plan"), findsNothing);
      expect(find.text('Review my plan'), findsNothing);
      final saved = await history(tester);
      expect(saved.plans, hasLength(2));
      expect(saved.current.startDay, _nov(9));
      expect(saved.current.startLimit, 11);
      expect(saved.current.quitDay, LogicalDay(2027, 1, 25));
      expect(saved.current.stages.first.number, 1);
      expect(saved.limitOn(_nov(8)), 9);
      expect((await onlyCheck(tester)).answeredAt, isNotNull);

      // The plan report lists the earlier plan's stages under Behind you.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      final report = container.read(planReportProvider(habitId)).value!;
      expect(report.behind, isNotEmpty);

      await tester.disposeApp();
    });

    testWidgets('Keep answers without a new plan', (tester) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      await tester.tap(find.text('Keep my plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Keep my plan'));
      await tester.pumpAndSettle();

      expect(find.text("Let's look at the plan"), findsNothing);
      expect(find.text('Review my plan'), findsNothing);
      expect((await history(tester)).plans, hasLength(1));
      expect((await onlyCheck(tester)).answeredAt, isNotNull);

      await tester.disposeApp();
    });

    testWidgets('closes at the reset hour, so no plan starts yesterday', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      (sl<Clock>() as FixedClock).current = DateTime(2026, 11, 10, 4, 1);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text("Let's look at the plan"), findsNothing);
      expect(find.text('Review my plan'), findsOneWidget);
      expect((await history(tester)).plans, hasLength(1));
      expect((await onlyCheck(tester)).answeredAt, isNull);

      await tester.disposeApp();
    });

    testWidgets('a failed save keeps the sheet and changes nothing', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');
      spy.failAnswer = true;

      await tester.tap(find.widgetWithText(FilledButton, 'Shake on it again'));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save that. Please try again."),
        findsOneWidget,
      );
      expect(find.text("Let's look at the plan"), findsOneWidget);
      expect((await history(tester)).plans, hasLength(1));
      expect((await onlyCheck(tester)).answeredAt, isNull);

      await tester.disposeApp();
    });

    testWidgets('two presses save once', (tester) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');
      spy.gate = Completer<void>();

      final button = find.widgetWithText(FilledButton, 'Shake on it again');
      await tester.tap(button);
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
      await tester.pump();
      spy.gate!.complete();
      await tester.pumpAndSettle();

      expect(spy.answers, 1);

      await tester.disposeApp();
    });

    testWidgets('fits its content, with no space under the footer', (
      tester,
    ) async {
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final sheet = tester.getRect(find.byType(AppSheetFrame));
      expect(sheet.height, lessThan(screen * 0.6));
      final foot = tester.getRect(
        find.text('Past days keep their limits. Stages start again at 1.'),
      );
      expect(sheet.bottom - foot.bottom, lessThan(40));

      await tester.disposeApp();
    });

    testWidgets('scrolls to the button at the largest text size', (
      tester,
    ) async {
      await loadAppFonts();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await seedReview(tester);
      await openSheet(tester, 'Review my plan');

      await tester.scrollUntilVisible(
        find.text('Shake on it again'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(StageChoiceSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(find.text('Shake on it again').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.clippedTexts(within: find.byType(StageChoiceSheet)),
        isEmpty,
      );

      await tester.disposeApp();
    });
  });

  group('reassess sheet', () {
    Future<void> seedReassess(
      WidgetTester tester, {
      Habit habit = Habit.smoking,
      int? priceCents,
    }) async {
      await tester.runAsync(() async {
        await start(habit: habit, priceCents: priceCents);
        // 8 a day over the fortnight: 7 a day under the first limit of 12.
        for (var d = 26; d <= 31; d++) {
          await logDay(_oct(d), 8);
        }
        for (var d = 1; d <= 8; d++) {
          await logDay(_nov(d), 8);
        }
        await record(StageOutcome.reassess);
      });
      await pumpHome(tester);
    }

    testWidgets('shows what is still yours, as Plan details does', (
      tester,
    ) async {
      await seedReassess(tester, priceCents: 1000);
      await openSheet(tester, 'Have a look');

      final container = ProviderScope.containerOf(
        tester.element(find.byType(StageCards)),
      );
      final totals = container.read(planReportProvider(habitId)).value!.totals;

      expect(find.text('Back around where you started'), findsOneWidget);
      expect(
        find.text(
          'About 8 a day these last two weeks. It happens, and none of this '
          'gets wiped.',
        ),
        findsOneWidget,
      );
      expect(find.text('Still yours'), findsOneWidget);
      expect(find.text(AppFormat.count(totals.avoided)), findsOneWidget);
      expect(find.text('avoided'), findsOneWidget);
      expect(find.text('saved'), findsOneWidget);
      expect(find.text(AppFormat.count(totals.kept)), findsOneWidget);
      expect(find.text('days kept'), findsOneWidget);
      expect(find.text('Start again from 8'), findsOneWidget);
      expect(find.text('Keep my plan'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('hides saved for a habit with no cost', (tester) async {
      await seedReassess(tester, habit: Habit.socialMedia);
      await openSheet(tester, 'Have a look');

      expect(find.text('Still yours'), findsOneWidget);
      expect(find.text('avoided'), findsOneWidget);
      expect(find.text('saved'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('closes with the nicotine support line', (tester) async {
      await seedReassess(tester, habit: Habit.vaping);
      await openSheet(tester, 'Have a look');

      await tester.scrollUntilVisible(
        find.textContaining('doctor, pharmacist'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(StageChoiceSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(
        find.text(
          'If this keeps being hard, a doctor, pharmacist or local quit '
          'service can help.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining("don't stop suddenly"), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('adds the alcohol line for alcohol only', (tester) async {
      await seedReassess(tester, habit: Habit.alcohol);
      await openSheet(tester, 'Have a look');

      await tester.scrollUntilVisible(
        find.textContaining("don't stop suddenly"),
        200,
        scrollable: find
            .descendant(
              of: find.byType(StageChoiceSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(
        find.text(
          'If this keeps being hard, a doctor or local support service can '
          'help.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          "If you drink heavily, don't stop suddenly without medical advice. "
          'It can be dangerous.',
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets('starting again saves the plan and clears the card', (
      tester,
    ) async {
      await seedReassess(tester);
      await openSheet(tester, 'Have a look');

      await tester.tap(find.widgetWithText(FilledButton, 'Shake on it again'));
      await tester.pumpAndSettle();

      expect(find.text('Have a look'), findsNothing);
      final saved = await history(tester);
      expect(saved.plans, hasLength(2));
      expect(saved.current.startLimit, 8);
      expect(saved.current.stages.first.number, 1);

      await tester.disposeApp();
    });
  });
}
