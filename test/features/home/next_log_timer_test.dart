import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/widgets/draining_ring.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);
  final clock = FixedClock(DateTime(2026, 10, 29, 9));
  const prompt = 'Set your day to get a pace guide';
  const count = Key('day-count');

  setUp(() {
    clock.current = DateTime(2026, 10, 29, 9);
    return setUpTestDependencies(clock);
  });
  tearDown(InjectionContainer.reset);

  Future<void> setWindow() async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
    );
  }

  Future<int> startPlan() => seedHabit(
    PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
  );

  Future<void> logAt(int habitId, DateTime at) =>
      sl<AddHabitLog>()(AddHabitLogInput(habitId: habitId, loggedAt: at));

  testWidgets('the ring counts down with hours, the + chip in minutes', (
    tester,
  ) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('2:42:52'), findsOneWidget);
    expect(find.text('until your next'), findsOneWidget);
    expect(find.text('1 of 8 · 7 left'), findsOneWidget);
    expect(find.byKey(count), findsNothing);
    expect(find.text('163 min'), findsOneWidget);
    expect(find.text('About one every 2 h 5 min until bed'), findsOneWidget);
    expect(find.text(prompt), findsNothing);
    expect(find.textContaining('Next one on schedule'), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('under an hour still shows the hour', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    clock.current = DateTime(2026, 10, 29, 11);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('0:42:52'), findsOneWidget);
    expect(find.text('43 min'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('both rings drain over the gap', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));

    await tester.pumpAppPastSplash(height: 2400);

    final rings = tester.widgetList<DrainingRing>(find.byType(DrainingRing));
    expect(rings, hasLength(2));
    // 2:42:51 left of a 3:42:51 gap: 2:12:51 plus the 1:30 that was left.
    for (final ring in rings) {
      expect(ring.fraction, closeTo(0.7308, 0.001));
    }
    await tester.disposeApp();
  });

  testWidgets('past zero it counts up and the + shows nothing', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    clock.current = DateTime(2026, 10, 29, 12);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('+0:17:08'), findsOneWidget);
    expect(find.text("You're on schedule"), findsOneWidget);
    expect(find.text('1 of 8 · 7 left'), findsOneWidget);
    expect(find.byKey(const Key('next-log-chip')), findsNothing);
    expect(find.text('About one every 2 h until bed'), findsOneWidget);
    expect(find.byType(DrainingRing), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('it ticks each second', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.text('2:42:52'), findsOneWidget);

    clock.current = DateTime(2026, 10, 29, 9, 0, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('2:42:51'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a fresh log restarts the gap from the real time', (
    tester,
  ) async {
    await setWindow();
    final habitId = await startPlan();
    await tester.pumpAppPastSplash(height: 2400);

    clock.current = DateTime(2026, 10, 29, 9, 0, 55);
    await tester.runAsync(() => logAt(habitId, clock.current));
    await tester.pumpAndSettle();

    expect(find.text('1 of 8 · 7 left'), findsOneWidget);
    expect(find.text('2:33:15'), findsOneWidget);
    expect(find.text('154 min'), findsOneWidget);
    expect(find.text('About one every 2 h 5 min until bed'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets(
    'an early log adds what was left, and removing it takes it back',
    (tester) async {
      await setWindow();
      final habitId = await startPlan();
      clock.current = DateTime(2026, 10, 29, 11);
      await logAt(habitId, DateTime(2026, 10, 29, 9, 30));
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.text('0:30:00'), findsOneWidget);

      final early = await tester.runAsync(
        () => sl<AddHabitLog>()(
          AddHabitLogInput(habitId: habitId, loggedAt: clock.current),
        ),
      );
      await tester.pumpAndSettle();

      // 125 min for the new gap, plus the 30 that were left.
      expect(find.text('2:35:00'), findsOneWidget);
      expect(find.text('155 min'), findsOneWidget);

      await tester.runAsync(
        () => sl<HabitLogRepository>().deleteLog(
          (early! as Success<HabitLog>).value.id,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0:30:00'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      await tester.disposeApp();
    },
  );

  testWidgets('a late evening keeps the even pace, not a catch-up one', (
    tester,
  ) async {
    await setWindow();
    final habitId = await startPlan();
    await logAt(habitId, DateTime(2026, 10, 29, 8));
    clock.current = DateTime(2026, 10, 29, 20);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text("You're on schedule"), findsOneWidget);
    expect(find.text('About one every 2 h until bed'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('hides the pace when one gap would run past bed', (tester) async {
    await setWindow();
    final habitId = await startPlan();
    await logAt(habitId, DateTime(2026, 10, 29, 8));
    clock.current = DateTime(2026, 10, 29, 23, 29);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text("You're on schedule"), findsOneWidget);
    expect(find.textContaining('About one every'), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('a log from yesterday does not count as the last one', (
    tester,
  ) async {
    await setWindow();
    final start = today.addDays(-1);
    final habitId = await seedHabit(
      PlanDraft(startDay: start, startLimit: 8, quitDay: start.addDays(56)),
    );
    await logAt(habitId, DateTime(2026, 10, 28, 22));
    clock.current = DateTime(2026, 10, 29, 7, 30);

    await tester.pumpAppPastSplash(height: 2400);

    // The limit is 8 today: 16 h / 8 from wake, not from last night's log.
    expect(find.text('2:00:00'), findsOneWidget);
    expect(find.text('120 min'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the chip stays on Settings', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('163 min'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the ring and + describe the timer to VoiceOver', (tester) async {
    final handle = tester.ensureSemantics();
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    await tester.pumpAppPastSplash(height: 2400);

    expect(
      find.bySemanticsLabel(
        'Next one on schedule in 2 h 43 min. 1 of 8 today, 7 left.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Next one on schedule in 163 min'),
      findsOneWidget,
    );
    handle.dispose();
    await tester.disposeApp();
  });

  group('one text under the ring', () {
    testWidgets('no logs today: the first-day note, not the pace', (
      tester,
    ) async {
      await setWindow();
      await startPlan();

      await tester.pumpAppPastSplash(height: 2400);

      expect(find.textContaining('logged today. Nice start.'), findsOneWidget);
      expect(find.textContaining('About one every'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('over the limit: the note, with no timer or pace', (
      tester,
    ) async {
      await setWindow();
      final habitId = await startPlan();
      for (var minute = 0; minute < 9; minute++) {
        await logAt(habitId, DateTime(2026, 10, 29, 8, minute));
      }

      await tester.pumpAppPastSplash(height: 2400);
      await tester.pumpInSteps(const Duration(seconds: 3));

      expect(find.textContaining('A harder day.'), findsOneWidget);
      expect(find.textContaining('About one every'), findsNothing);
      expect(find.byKey(count), findsOneWidget);
      expect(find.byType(DrainingRing), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('a past day shows the count and no pace', (tester) async {
      await setWindow();
      final start = today.addDays(-1);
      final habitId = await seedHabit(
        PlanDraft(startDay: start, startLimit: 8, quitDay: start.addDays(56)),
      );
      await logAt(habitId, DateTime(2026, 10, 29, 8));
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.textContaining('About one every'), findsOneWidget);

      final previous = find.byTooltip('Previous day');
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      await tester.tap(previous);
      await tester.pumpAndSettle();

      expect(find.text('Wednesday, Oct 28'), findsOneWidget);
      expect(find.byKey(count), findsOneWidget);
      expect(find.textContaining('About one every'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('without a day window, the prompt sets one', (tester) async {
      final habitId = await startPlan();
      await logAt(habitId, DateTime(2026, 10, 29, 8));
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.text(prompt), findsOneWidget);
      expect(find.byKey(count), findsOneWidget);
      expect(find.byType(DrainingRing), findsNothing);

      await tester.scrollAndTap(find.text(prompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text(prompt), findsNothing);
      expect(find.textContaining('About one every'), findsOneWidget);
      expect(find.byKey(count), findsNothing);
      final stored = await tester.runAsync(
        () => sl<SettingsRepository>().get(),
      );
      final settings = (stored! as Success<AppSettings>).value;
      expect(settings.wakeMinute, 450);
      expect(settings.bedMinute, 1410);
      await tester.disposeApp();
    });
  });

  group('no timer', () {
    Future<void> expectNoTimer(WidgetTester tester) async {
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.byKey(count), findsOneWidget);
      expect(find.byType(DrainingRing), findsNothing);
      expect(find.text('until your next'), findsNothing);
      expect(find.textContaining('on schedule'), findsNothing);
      expect(find.textContaining('About one every'), findsNothing);
      expect(find.text(prompt), findsNothing);
      await tester.disposeApp();
    }

    testWidgets('at the limit', (tester) async {
      await setWindow();
      final habitId = await startPlan();
      for (var hour = 0; hour < 8; hour++) {
        await logAt(habitId, DateTime(2026, 10, 29, 7, hour));
      }
      await expectNoTimer(tester);
    });

    testWidgets('on quit day', (tester) async {
      await setWindow();
      await seedHabit(
        PlanDraft(startDay: today.addDays(-14), startLimit: 8, quitDay: today),
      );
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.byType(DrainingRing), findsNothing);
      expect(find.text('until your next'), findsNothing);
      expect(find.textContaining('About one every'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('before wake', (tester) async {
      await setWindow();
      final habitId = await startPlan();
      await logAt(habitId, DateTime(2026, 10, 29, 5));
      clock.current = DateTime(2026, 10, 29, 6);
      await expectNoTimer(tester);
    });
  });

  testWidgets('a large text size stays inside the inner ring', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpAppPastSplash(height: 2400);
    // Other cards overflow at this size; Task 5.2 owns them.
    tester.takeException();

    final inner = tester.getSize(find.byType(DrainingRing).first).width;
    expect(
      tester.getRect(find.text('2:42:52')).width,
      lessThanOrEqualTo(inner),
    );
    await tester.disposeApp();
  });
}
