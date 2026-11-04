import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/widgets/quit_reached_card.dart';
import 'package:exhale/features/home/presentation/widgets/stage_cards.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/usecases/answer_stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
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

  tearDown(InjectionContainer.reset);

  /// Starts the app on [now] with [plan] tracked.
  Future<void> start(DateTime now, {PlanDraft? plan}) async {
    await setUpTestDependencies(FixedClock(now));
    habitId = await seedHabit(plan ?? weekly);
    spy = _SpyChecks(sl<StageCheckRepository>());
    sl
      ..unregister<AnswerStageCheck>()
      ..registerFactory(() => AnswerStageCheck(spy, sl<Clock>()));
  }

  Future<void> logDay(LogicalDay day, int count) async {
    for (var i = 0; i < count; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: habitId,
          loggedAt: DateTime(day.year, day.month, day.day, 12, i),
        ),
      );
    }
  }

  /// 74 logged in Nov 2 to 8 against an allowed 63.
  Future<void> logFailingWeek() async {
    for (var d = 2; d <= 8; d++) {
      await logDay(_nov(d), d <= 5 ? 11 : 10);
    }
  }

  Future<void> record(
    StageOutcome outcome, {
    required LogicalDay windowEnd,
    required LogicalDay checkDay,
    LogicalDay? planStart,
    PlanHold? hold,
  }) async {
    final result = await sl<StageCheckRepository>().record(
      habitId,
      StageCheck(
        planStartDay: planStart ?? _oct(12),
        windowEndDay: windowEnd,
        checkDay: checkDay,
        outcome: outcome,
      ),
      hold: hold,
    );
    expect(result, isA<Success<void>>());
  }

  Future<void> pumpHome(WidgetTester tester) =>
      tester.pumpAppPastSplash(height: 2400);

  Finder inCards(Finder finder) =>
      find.descendant(of: find.byType(StageCards), matching: finder);

  group('hold card', () {
    final nov9 = DateTime(2026, 11, 9, 15, 42);

    Future<void> holdOnNov9(WidgetTester tester) async {
      await tester.runAsync(() async {
        await start(nov9);
        await logFailingWeek();
        await record(
          StageOutcome.hold,
          windowEnd: _nov(8),
          checkDay: _nov(9),
          hold: PlanHold(startDay: _nov(9)),
        );
      });
      await pumpHome(tester);
    }

    BoxDecoration tileOf(WidgetTester tester, String label) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: inCards(find.text(label)),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    testWidgets('date tiles are solid with a border in light mode', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await holdOnNov9(tester);

      final colors = Theme.of(tester.element(find.text('Next drop')))
          .colorScheme;
      expect(colors.brightness, Brightness.light);
      for (final label in ['Next drop', 'Quit date']) {
        final tile = tileOf(tester, label);
        expect(tile.color, colors.surface);
        expect(tile.border, Border.all(color: colors.outlineVariant));
      }

      await tester.disposeApp();
    });

    testWidgets('date tiles stay soft in dark mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await holdOnNov9(tester);

      final colors = Theme.of(tester.element(find.text('Next drop')))
          .colorScheme;
      expect(colors.brightness, Brightness.dark);
      final tile = tileOf(tester, 'Next drop');
      expect(tile.color, colors.surface.withValues(alpha: 0.6));
      expect(tile.border, isNull);

      await tester.disposeApp();
    });

    testWidgets('shows the copy of the mock', (tester) async {
      await holdOnNov9(tester);

      expect(inCards(find.text('8 can wait.')), findsOneWidget);
      expect(
        inCards(
          find.text(
            'Last week came to 74 against an allowed 63, so you stay at 9 '
            "for one more week. Nothing's lost.",
          ),
        ),
        findsOneWidget,
      );
      expect(inCards(find.text('Next drop')), findsOneWidget);
      expect(inCards(find.text('Nov 16')), findsOneWidget);
      expect(inCards(find.text('Was today')), findsOneWidget);
      expect(inCards(find.text('Quit date')), findsOneWidget);
      expect(inCards(find.text('Jan 11')), findsOneWidget);
      expect(inCards(find.text('Was Jan 4')), findsOneWidget);
      expect(inCards(find.text('Keep Jan 4')), findsOneWidget);
      expect(inCards(find.text('Got it')), findsOneWidget);
      expect(
        inCards(
          find.text(
            'Keep Jan 4 moves you to 8 today. You can choose it until '
            'tonight, then Edit plan is the way.',
          ),
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets("Keep restores today's limit and removes the card", (
      tester,
    ) async {
      await holdOnNov9(tester);

      await tester.tap(inCards(find.text('Keep Jan 4')));
      await tester.pumpAndSettle();

      expect(inCards(find.text('Got it')), findsNothing);
      final history = await tester.runAsync(
        () => sl<PlanRepository>().getHistory(habitId),
      );
      final plan = (history! as Success<PlanHistory?>).value!.current;
      expect(plan.holds, isEmpty);
      expect(plan.quitDay, LogicalDay(2027, 1, 4));
      expect(plan.limitOn(_nov(9)), 8);

      await tester.disposeApp();
    });

    testWidgets('Got it answers and removes the card', (tester) async {
      await holdOnNov9(tester);

      await tester.tap(inCards(find.text('Got it')));
      await tester.pumpAndSettle();

      expect(inCards(find.text('8 can wait.')), findsNothing);
      final checks = await tester.runAsync(
        () => sl<StageCheckRepository>().getChecks(habitId),
      );
      final stored = (checks! as Success<List<StageCheck>>).value.single;
      expect(stored.answeredAt, isNotNull);

      await tester.disposeApp();
    });

    testWidgets('a failed save keeps the card and shows a snackbar', (
      tester,
    ) async {
      await holdOnNov9(tester);
      spy.failAnswer = true;

      await tester.tap(inCards(find.text('Got it')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save that. Please try again."),
        findsOneWidget,
      );
      expect(inCards(find.text('8 can wait.')), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('two presses save once', (tester) async {
      await holdOnNov9(tester);
      spy.gate = Completer<void>();

      await tester.tap(inCards(find.text('Got it')));
      await tester.pump();
      await tester.tap(inCards(find.text('Got it')));
      await tester.pump();
      spy.gate!.complete();
      await tester.pumpAndSettle();

      expect(spy.answers, 1);

      await tester.disposeApp();
    });

    testWidgets('the last stage says Zero can wait', (tester) async {
      // 7 a day from Oct 12 over 14 days; the last stage is Oct 24 and 25.
      await tester.runAsync(() async {
        await start(
          DateTime(2026, 10, 26, 15, 42),
          plan: PlanDraft(startDay: _oct(12), startLimit: 7, quitDay: _oct(26)),
        );
        await record(
          StageOutcome.hold,
          windowEnd: _oct(25),
          checkDay: _oct(26),
          hold: PlanHold(startDay: _oct(26)),
        );
      });
      await pumpHome(tester);

      expect(inCards(find.text('Zero can wait.')), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a late open says until the next drop', (tester) async {
      await tester.runAsync(() async {
        await start(DateTime(2026, 11, 10, 15, 42));
        await logFailingWeek();
        await record(
          StageOutcome.hold,
          windowEnd: _nov(8),
          checkDay: _nov(10),
          hold: PlanHold(startDay: _nov(9)),
        );
      });
      await pumpHome(tester);

      expect(
        inCards(find.textContaining('so you stay at 9 until Nov 16. Nothing')),
        findsOneWidget,
      );
      expect(inCards(find.text('Was Nov 9')), findsOneWidget);
      expect(inCards(find.text('Keep Jan 4')), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('the next day only Got it stays', (tester) async {
      await tester.runAsync(() async {
        await start(DateTime(2026, 11, 10, 15, 42));
        await logFailingWeek();
        await record(
          StageOutcome.hold,
          windowEnd: _nov(8),
          checkDay: _nov(9),
          hold: PlanHold(startDay: _nov(9)),
        );
      });
      await pumpHome(tester);

      expect(inCards(find.text('Got it')), findsOneWidget);
      expect(inCards(find.text('Keep Jan 4')), findsNothing);
      expect(inCards(find.textContaining('You can choose it')), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('fits at the largest text size', (tester) async {
      await loadAppFonts();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await holdOnNov9(tester);

      expect(tester.takeException(), isNull);
      expect(tester.clippedTexts(within: find.byType(StageCards)), isEmpty);

      await tester.disposeApp();
    });

    testWidgets('shows on today only', (tester) async {
      await holdOnNov9(tester);
      expect(inCards(find.text('8 can wait.')), findsOneWidget);

      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      expect(inCards(find.text('8 can wait.')).hitTestable(), findsNothing);

      await tester.disposeApp();
    });
  });

  group('review card', () {
    testWidgets('names the limit and has no dismiss', (tester) async {
      // 12 a day with a drop every 14 days: Oct 12 to 25 is all at 12.
      await tester.runAsync(() async {
        await start(
          DateTime(2026, 10, 26, 15, 42),
          plan: PlanDraft(
            startDay: _oct(12),
            startLimit: 12,
            quitDay: _oct(12).addDays(168),
          ),
        );
        await record(
          StageOutcome.review,
          windowEnd: _oct(25),
          checkDay: _oct(26),
        );
      });
      await pumpHome(tester);

      expect(inCards(find.text("This pace isn't fitting.")), findsOneWidget);
      expect(
        inCards(
          find.text(
            'Two weeks over 12 a day. The plan can bend, and you decide how.',
          ),
        ),
        findsOneWidget,
      );
      expect(inCards(find.text('Review my plan')), findsOneWidget);
      expect(inCards(find.byType(FilledButton)), findsOneWidget);
      expect(inCards(find.byType(OutlinedButton)), findsNothing);
      expect(inCards(find.byType(TextButton)), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('drops the number when the fortnight had two limits', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await start(DateTime(2026, 11, 9, 15, 42));
        await record(
          StageOutcome.review,
          windowEnd: _nov(8),
          checkDay: _nov(9),
        );
      });
      await pumpHome(tester);

      expect(
        inCards(
          find.text(
            'Two weeks over your limit. The plan can bend, and you decide '
            'how.',
          ),
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets('takes its limits from the two failed windows', (tester) async {
      // A drop every 14 days: 12 until Oct 25, held to Nov 1, then 11 to
      // Nov 15. The 14 days before the review are all at 11.
      await tester.runAsync(() async {
        await start(
          DateTime(2026, 11, 16, 15, 42),
          plan: PlanDraft(
            startDay: _oct(12),
            startLimit: 12,
            quitDay: _oct(12).addDays(168),
          ),
        );
        await record(
          StageOutcome.hold,
          windowEnd: _oct(25),
          checkDay: _oct(26),
          hold: PlanHold(startDay: _oct(26)),
        );
        await spy.answer(
          habitId,
          _oct(12),
          _oct(25),
          DateTime(2026, 10, 26, 9),
        );
        await record(
          StageOutcome.review,
          windowEnd: _nov(15),
          checkDay: _nov(16),
        );
      });
      await pumpHome(tester);

      expect(
        inCards(
          find.text(
            'Two weeks over your limit. The plan can bend, and you decide '
            'how.',
          ),
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets('hides the quit-date card', (tester) async {
      await tester.runAsync(() async {
        await start(
          DateTime(2026, 11, 9, 15, 42),
          plan: PlanDraft(startDay: _oct(1), startLimit: 3, quitDay: _oct(22)),
        );
        await record(
          StageOutcome.review,
          windowEnd: _oct(14),
          checkDay: _oct(15),
          planStart: _oct(1),
        );
      });
      await pumpHome(tester);

      expect(find.text('Review my plan'), findsOneWidget);
      expect(find.byType(QuitReachedCard), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('saving a new plan removes the card for good', (tester) async {
      await tester.runAsync(() async {
        await start(DateTime(2026, 11, 9, 15, 42));
        await record(
          StageOutcome.review,
          windowEnd: _nov(8),
          checkDay: _nov(9),
        );
      });
      await pumpHome(tester);
      expect(find.text('Review my plan'), findsOneWidget);

      await tester.runAsync(
        () => sl<SavePlan>()((
          habitId: habitId,
          draft: PlanDraft(
            startDay: _nov(9),
            startLimit: 8,
            quitDay: _nov(9).addDays(56),
          ),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review my plan'), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Review my plan'), findsNothing);
      expect(find.text("This pace isn't fitting."), findsNothing);

      await tester.disposeApp();
    });
  });

  group('reassess card', () {
    testWidgets('shows the average of the fortnight', (tester) async {
      await tester.runAsync(() async {
        await start(DateTime(2026, 11, 9, 15, 42));
        // 30 logs over the 14 days ending Nov 8: about 3 a day.
        await logDay(_nov(5), 15);
        await logDay(_nov(8), 15);
        await record(
          StageOutcome.reassess,
          windowEnd: _nov(8),
          checkDay: _nov(9),
        );
      });
      await pumpHome(tester);

      expect(
        inCards(find.text('Back around where you started.')),
        findsOneWidget,
      );
      expect(
        inCards(find.text("About 3 a day lately. Nothing's been wiped.")),
        findsOneWidget,
      );
      expect(inCards(find.text('Have a look')), findsOneWidget);

      await tester.disposeApp();
    });
  });
}
