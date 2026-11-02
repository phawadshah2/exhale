import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boundary = DayBoundary();
  final start = LogicalDay(2026, 10, 8);
  final quit = LogicalDay(2026, 12, 31);
  final nov1 = LogicalDay(2026, 11, 1);
  final plan = ReductionPlan(startDay: start, startLimit: 12, quitDay: quit);
  final history = PlanHistory([plan]);

  // Frame K's sessions per day, 8 Oct to 1 Nov.
  const kUsed = [
    11, 12, 11, 14, 11, 10, 10, // limit 12
    11, 11, 13, 12, 11, 10, 10, // limit 11
    9, 9, 12, 9, 9, 8, 10, // limit 10
    8, 11, 9, 5, // limit 9, today last
  ];

  PriceHistory priced(int cents, {LogicalDay? from}) =>
      PriceHistory.forHabit(Habit.caffeine, [
        PricePoint(
          fromDay: from ?? start,
          priceCents: cents,
          unitsPerContainer: 20,
        ),
      ]);

  var nextId = 1;
  List<HabitLog> logsFrom(
    LogicalDay first,
    List<int> counts, {
    Trigger? trigger,
  }) => [
    for (final (offset, count) in counts.indexed)
      for (var i = 0; i < count; i++)
        HabitLog(
          id: nextId++,
          loggedAt: first
              .addDays(offset)
              .toLocalDate()
              .add(Duration(hours: 9, minutes: i)),
          habitId: 1,
          trigger: trigger,
        ),
  ];

  PlanReport report({
    List<HabitLog>? logs,
    PlanHistory? plans,
    PriceHistory? prices,
    LogicalDay? today,
  }) => PlanReport.build(
    logs: logs ?? logsFrom(start, kUsed),
    boundary: boundary,
    history: plans ?? history,
    prices: prices,
    today: today ?? nov1,
  );

  group("frame K's data", () {
    late PlanReport k;

    setUp(() => k = report(prices: priced(40)));

    test('the "of" figures span the whole plan', () {
      expect(k.totals.usedOf, 546);
      expect(k.totals.avoidedOf, 462);
      expect(k.totals.savedOfCents, 18480);
      expect(k.totals.withoutPlanUnits, 1008);
      expect(k.totals.withoutPlanCents, 40320);
      expect(k.totals.keptOf, 24);
    });

    test('used counts through today; kept only finished days', () {
      expect(k.totals.used, 256);
      expect(k.totals.kept, 19);
    });

    test("avoided and saved equal Home's on the same data", () {
      final logs = logsFrom(start, kUsed);
      final stats = ProgressCalculator.homeStats(
        days: buildDailyProgress(
          logs: logs,
          boundary: boundary,
          history: history,
          from: start,
          to: nov1,
        ),
        history: history,
        today: nov1,
        prices: priced(40),
      );

      final built = report(logs: logs, prices: priced(40));
      expect(built.totals.avoided, stats.avoided);
      expect(built.totals.savedCents, stats.moneySavedCents);
      expect(built.totals.avoided, 37);
      expect(built.totals.savedCents, 1480);
    });

    test('behind plus the current stage equals the total saved', () {
      expect(k.behindSavedCents! + k.current!.savedCents!, k.totals.savedCents);
    });

    test('stages sit behind, current and ahead, oldest first', () {
      expect(k.stageCount, 12);
      expect(k.quitDay, quit);
      expect(k.quitReached, isFalse);
      expect(k.showsThisPlanLabel, isFalse);
      expect(k.behind.single.earlierUntil, isNull);
      expect(k.behind.single.stages.map((s) => s.stage.number), [1, 2, 3]);
      expect(k.current!.stage.number, 4);
      expect(k.ahead.map((s) => s.stage.number), [5, 6, 7, 8, 9, 10, 11, 12]);
    });

    test('an ended stage has its figures', () {
      final [first, second, _] = k.behind.single.stages;

      expect(first.lastDay, LogicalDay(2026, 10, 14));
      expect(first.days, 7);
      expect(first.used, 79);
      expect(first.allowed, 84);
      expect(first.daysOver, 1);
      expect(first.average, 79 / 7);
      expect(first.savedCents, 200);
      expect(first.isOverAllowed, isFalse);
      expect(first.daily, hasLength(7));

      expect(second.used, 78);
      expect(second.allowed, 77);
      expect(second.daysOver, 2);
      expect(second.isOverAllowed, isTrue);
    });

    test('the current stage counts today in used, not in saved', () {
      final current = k.current!;

      expect(current.lastDay, LogicalDay(2026, 11, 4));
      expect(current.days, 7);
      expect(current.used, 33);
      expect(current.allowed, 63);
      expect(current.daysOver, 1);
      expect(current.savedCents, 320);
      expect(current.toSaveCents, 840);
      expect(current.daily, hasLength(4));
      expect(current.note, isNull);
    });

    test('a stage ahead has only what it will be', () {
      final next = k.ahead.first;

      expect(next.used, 0);
      expect(next.allowed, 56);
      expect(next.daily, isEmpty);
      expect(next.savedCents, 0);
      expect(next.toSaveCents, 1120);
      expect(k.aheadToSaveCents, 16800);
    });
  });

  test("today's over limit counts in the stage's days over", () {
    final over = report(logs: logsFrom(start, [...kUsed.take(24), 10]));

    expect(over.current!.daysOver, 2);
    expect(over.totals.kept, 19);
  });

  test('a stage above the baseline stays negative so the sums hold', () {
    final first = LogicalDay(2026, 10, 1);
    final five = ReductionPlan(
      startDay: first,
      startLimit: 5,
      quitDay: first.addDays(35),
    );
    final built = report(
      logs: logsFrom(first, [8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1]),
      plans: PlanHistory([five]),
      prices: priced(40, from: first),
      today: first.addDays(14),
    );

    expect(built.behind.single.stages.first.savedCents, -840);
    expect(built.behindSavedCents, 280);
    expect(built.behindSavedCents! + built.current!.savedCents!, 280);
    expect(built.totals.savedCents, 280);
  });

  group('after a replan', () {
    final oct20 = LogicalDay(2026, 10, 20);
    final oct19 = LogicalDay(2026, 10, 19);
    final replanned = history.replan(
      ReductionPlan(
        startDay: oct20,
        startLimit: 10,
        quitDay: LogicalDay(2026, 12, 1),
      ),
    );
    late PlanReport built;

    setUp(() => built = report(plans: replanned, prices: priced(40)));

    test('earlier stages sit under their own group', () {
      final [earlier, thisPlan] = built.behind;

      expect(earlier.earlierUntil, oct19);
      expect(earlier.stages.map((s) => s.stage.number), [1, 2]);
      expect(thisPlan.earlierUntil, isNull);
      expect(thisPlan.stages.first.stage.number, 1);
      expect(thisPlan.stages.first.stage.limit, 10);
      expect(built.showsThisPlanLabel, isTrue);
    });

    test("a cut-off stage's figures use its real days", () {
      final cut = built.behind.first.stages.last;

      expect(cut.lastDay, oct19);
      expect(cut.days, 5);
      expect(cut.allowed, 55);
      expect(cut.used, 11 + 11 + 13 + 12 + 11);
      expect(cut.daily, hasLength(5));
      expect(cut.daysOver, 2);
    });

    test('the new plan numbers its stages from 1', () {
      expect(built.stageCount, replanned.current.stageCount);
      expect(built.current!.stage, replanned.current.stageOn(nov1));
    });

    test('totals span both plans', () {
      var usedOf = 0;
      for (
        var day = start;
        day.isBefore(replanned.current.quitDay);
        day = day.addDays(1)
      ) {
        usedOf += replanned.limitOn(day);
      }

      expect(built.totals.usedOf, usedOf);
      expect(built.totals.used, 256);
      expect(built.totals.withoutPlanUnits, 12 * 54);
      expect(built.totals.keptOf, 24);
    });

    test('behind plus the current stage still equals the total', () {
      expect(
        built.behindSavedCents! + built.current!.savedCents!,
        built.totals.savedCents,
      );
    });

    test('a plan with no ended stages shows no "This plan" group', () {
      final fresh = report(plans: replanned, prices: priced(40), today: oct20);

      expect(fresh.behind.single.earlierUntil, oct19);
      expect(fresh.showsThisPlanLabel, isFalse);
    });

    test('a new goal after quitting: the old plan ends at its quit date', () {
      final first = LogicalDay(2026, 10, 1);
      final oldQuit = first.addDays(14);
      final newStart = first.addDays(20);
      final built = report(
        logs: logsFrom(first, const [1, 1, 1]),
        plans: PlanHistory([
          ReductionPlan(startDay: first, startLimit: 2, quitDay: oldQuit),
          ReductionPlan(
            startDay: newStart,
            startLimit: 3,
            quitDay: newStart.addDays(21),
          ),
        ]),
        today: newStart,
      );

      final earlier = built.behind.single;
      expect(earlier.earlierUntil, oldQuit.addDays(-1));
      expect(earlier.stages.map((s) => s.stage.number), [1, 2]);
      expect(built.current!.stage.limit, 3);
      expect(built.totals.keptOf, 20);
    });

    test('a replan above the baseline never goes negative', () {
      final first = LogicalDay(2026, 10, 1);
      final above = PlanHistory([
        ReductionPlan(
          startDay: first,
          startLimit: 5,
          quitDay: first.addDays(35),
        ),
        ReductionPlan(
          startDay: first.addDays(3),
          startLimit: 12,
          quitDay: first.addDays(60),
        ),
      ]);
      final high = report(
        logs: logsFrom(first, [9, 9, 9, 12, 12]),
        plans: above,
        prices: priced(40, from: first),
        today: first.addDays(5),
      );

      expect(high.totals.avoided, 0);
      expect(high.totals.savedCents, 0);
      expect(high.totals.avoidedOf, greaterThanOrEqualTo(0));
      expect(high.totals.savedOfCents, greaterThanOrEqualTo(0));
      expect(high.current!.toSaveCents, 0);
      expect(high.aheadToSaveCents, greaterThanOrEqualTo(0));
      expect(high.totals.withoutPlanUnits, greaterThan(0));
    });
  });

  test('first day: nothing kept and nothing behind', () {
    final built = report(logs: const [], prices: priced(40), today: start);

    expect(built.totals.kept, 0);
    expect(built.totals.keptOf, 0);
    expect(built.totals.used, 0);
    expect(built.totals.savedCents, 0);
    expect(built.behind, isEmpty);
    expect(built.behindSavedCents, 0);
    expect(built.current!.stage.number, 1);
  });

  for (final daysAfter in [0, 5]) {
    test('$daysAfter days after the quit date every stage is behind', () {
      final built = report(prices: priced(40), today: quit.addDays(daysAfter));

      expect(built.quitReached, isTrue);
      expect(built.current, isNull);
      expect(built.ahead, isEmpty);
      expect(built.aheadToSaveCents, 0);
      expect(built.behind.single.stages, hasLength(12));
      expect(built.totals.usedOf, 546);
      expect(built.totals.keptOf, 84 + daysAfter);
      expect(built.totals.withoutPlanUnits, 12 * (84 + daysAfter + 1));
    });
  }

  group('Mostly', () {
    test('is the top trigger of the stage', () {
      final built = report(
        logs: [
          ...logsFrom(start, [2], trigger: Trigger.values[1]),
          ...logsFrom(start, [3], trigger: Trigger.values[0]),
          ...logsFrom(start.addDays(1), [4]),
        ],
      );

      expect(built.behind.single.stages.first.mostly, Trigger.values[0]);
      expect(built.behind.single.stages[1].mostly, isNull);
    });

    test('is null when no log has a trigger', () {
      expect(report().behind.single.stages.first.mostly, isNull);
    });
  });

  group('money', () {
    test('no price: every money figure is null', () {
      final built = report();

      expect(built.totals.savedCents, isNull);
      expect(built.totals.savedOfCents, isNull);
      expect(built.totals.withoutPlanCents, isNull);
      expect(built.behindSavedCents, isNull);
      expect(built.aheadToSaveCents, isNull);
      expect(built.current!.savedCents, isNull);
      expect(built.current!.toSaveCents, isNull);
      expect(built.ahead.first.toSaveCents, isNull);
      expect(built.totals.withoutPlanUnits, 1008);
    });

    test('a cleared price: every money figure is null', () {
      final built = report(
        prices: PriceHistory.forHabit(Habit.caffeine, [
          PricePoint(fromDay: start, priceCents: 40, unitsPerContainer: 20),
          PricePoint(fromDay: nov1, priceCents: null, unitsPerContainer: 20),
        ]),
      );

      expect(built.totals.savedCents, isNull);
      expect(built.behindSavedCents, isNull);
    });

    test('a habit with no cost has no money', () {
      final built = report(
        prices: PriceHistory.forHabit(Habit.socialMedia, [
          PricePoint(fromDay: start, priceCents: 40, unitsPerContainer: 20),
        ]),
      );

      expect(built.totals.savedCents, isNull);
      expect(built.totals.withoutPlanCents, isNull);
    });

    test('past days use their own price, later days the current one', () {
      final built = report(
        prices: PriceHistory.forHabit(Habit.caffeine, [
          PricePoint(fromDay: start, priceCents: 40, unitsPerContainer: 20),
          PricePoint(fromDay: nov1, priceCents: 50, unitsPerContainer: 20),
        ]),
      );

      // 8 Oct to 31 Oct at 40, 1 Nov on at 50; limit 12 for the first 7 days.
      var savedOf = 0.0;
      var without = 0.0;
      for (var day = start; day.isBefore(quit); day = day.addDays(1)) {
        final price = day.isBefore(nov1) ? 40 : 50;
        savedOf += (12 - history.limitOn(day)) * price;
        without += 12 * price;
      }
      expect(built.totals.savedOfCents, savedOf);
      expect(built.totals.withoutPlanCents, without);
      expect(built.totals.savedCents, 1480);
      expect(built.behind.single.stages.first.savedCents, 200);
      expect(built.current!.toSaveCents, 3 * 7 * 50);
    });

    test('a day with no price counts nothing in its stage', () {
      final built = report(
        prices: PriceHistory.forHabit(Habit.caffeine, [
          PricePoint(fromDay: start, priceCents: 40, unitsPerContainer: 20),
          PricePoint(
            fromDay: LogicalDay(2026, 10, 15),
            priceCents: null,
            unitsPerContainer: 20,
          ),
          PricePoint(
            fromDay: LogicalDay(2026, 10, 22),
            priceCents: 40,
            unitsPerContainer: 20,
          ),
        ]),
      );

      expect(built.behind.single.stages[1].savedCents, 0);
      expect(built.totals.savedCents, 1480 - 240);
    });
  });

  group('notes, behind you', () {
    // Stages of 7 days at 9, 8, 7, ... from `first`.
    final first = LogicalDay(2026, 10, 1);
    final nine = PlanHistory([
      ReductionPlan(startDay: first, startLimit: 9, quitDay: first.addDays(63)),
    ]);

    List<StageNote?> notes(List<List<int>> stages, {PlanHistory? plans}) {
      final counts = [for (final stage in stages) ...stage];
      return report(
        logs: logsFrom(first, counts),
        plans: plans ?? nine,
        today: first.addDays(counts.length),
      ).behind.expand((g) => g.stages).map((s) => s.note).toList();
    }

    const under9 = [8, 8, 8, 8, 8, 8, 8];
    const under8 = [7, 7, 7, 7, 7, 7, 7];

    test('the first stage alone is the easy one', () {
      expect(notes([under9]), [StageNote.easyOne]);
    });

    test('with two ended the lowest share is the best, first in order', () {
      // 56/63 against 28/56.
      expect(
        notes([
          under9,
          const [4, 4, 4, 4, 4, 4, 4],
        ]),
        [StageNote.easyOne, StageNote.best],
      );
    });

    test('the best outranks the easy one', () {
      expect(
        notes([
          const [1, 1, 1, 1, 1, 1, 1],
          under8,
        ]),
        [StageNote.best, StageNote.noneOver],
      );
    });

    test('the best outranks days over', () {
      expect(
        notes([
          const [9, 9, 9, 9, 9, 9, 9],
          const [9, 1, 1, 1, 1, 1, 1],
        ]),
        [StageNote.easyOne, StageNote.best],
      );
    });

    test('a tie for the best goes to the oldest', () {
      // Both stages run 7 days at 9, one from each plan.
      expect(
        notes(
          [
            const [5, 5, 5, 5, 5, 5, 5],
            const [5, 5, 5, 5, 5, 5, 5],
          ],
          plans: PlanHistory([
            ReductionPlan(
              startDay: first,
              startLimit: 9,
              quitDay: first.addDays(63),
            ),
            ReductionPlan(
              startDay: first.addDays(7),
              startLimit: 9,
              quitDay: first.addDays(70),
            ),
          ]),
        ),
        [StageNote.best, StageNote.noneOver],
      );
    });

    test('no days, one day and several days over', () {
      expect(
        notes([
          under9,
          under8,
          const [8, 6, 6, 6, 6, 6, 6],
          const [7, 7, 5, 5, 5, 5, 5],
          const [1, 1, 1, 1, 1, 1, 1],
        ]),
        [
          StageNote.easyOne,
          StageNote.noneOver,
          StageNote.oneOver,
          StageNote.someOver,
          StageNote.best,
        ],
      );
    });

    test('only the first stage of the first plan is the easy one', () {
      final replanned = nine.replan(
        ReductionPlan(
          startDay: first.addDays(7),
          startLimit: 8,
          quitDay: first.addDays(63),
        ),
      );

      // The new plan's stage 1 runs 7 days at 8; the old stage 1 is the best.
      expect(
        notes([
          const [7, 7, 7, 7, 7, 7, 7],
          under8,
        ], plans: replanned),
        [StageNote.best, StageNote.noneOver],
      );
    });
  });

  group('notes, ahead of you', () {
    test("frame K's stages", () {
      final ahead = report().ahead;

      expect(ahead.map((s) => (s.stage.limit, s.note)), [
        (8, StageNote.oneFewer),
        (7, StageNote.written),
        (6, StageNote.halfway),
        (5, StageNote.written),
        (4, StageNote.written),
        (3, StageNote.written),
        (2, StageNote.written),
        (1, StageNote.last),
      ]);
    });

    test('the next stage outranks halfway', () {
      final today = LogicalDay(2026, 11, 18);

      expect(report(today: today).current!.stage.limit, 7);
      expect(report(today: today).ahead.first.stage.limit, 6);
      expect(report(today: today).ahead.first.note, StageNote.oneFewer);
    });

    test('the last stage outranks the next one', () {
      final today = quit.addDays(-8);

      expect(report(today: today).current!.stage.limit, 2);
      expect(report(today: today).ahead.single.note, StageNote.last);
    });

    test('a next stage that drops by 2 is not one fewer', () {
      final forty = PlanHistory([
        ReductionPlan(
          startDay: start,
          startLimit: 40,
          quitDay: start.addDays(20),
        ),
      ]);
      final ahead = report(logs: const [], plans: forty, today: start).ahead;

      expect(ahead.first.stage.limit, 38);
      expect(ahead.first.note, StageNote.written);
    });

    test('halfway is only the first stage at or below half the start', () {
      final notes = report().ahead.where((s) => s.note == StageNote.halfway);

      expect(notes.single.stage.limit, 6);
    });

    test('nothing ahead on the last stage', () {
      final built = report(today: quit.addDays(-1));

      expect(built.current!.stage.limit, 1);
      expect(built.ahead, isEmpty);
    });
  });
}
