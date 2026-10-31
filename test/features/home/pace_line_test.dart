import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);
  final clock = FixedClock(DateTime(2026, 10, 29, 9));
  const prompt = 'Set your day to get a pace guide';

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

  testWidgets('counts down to the next one on schedule', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Next one on schedule in 73 min'), findsOneWidget);
    expect(find.text('About one every 125 min until bed'), findsOneWidget);
    expect(find.text(prompt), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('says on schedule once the next one has passed', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    clock.current = DateTime(2026, 10, 29, 12);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text("You're on schedule"), findsOneWidget);
    expect(find.text('About one every 99 min until bed'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the minute tick moves the line on', (tester) async {
    await setWindow();
    await logAt(await startPlan(), DateTime(2026, 10, 29, 8));
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.text('Next one on schedule in 73 min'), findsOneWidget);

    clock.current = DateTime(2026, 10, 29, 10, 30);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(find.text("You're on schedule"), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('never says every 0 min close to bedtime', (tester) async {
    await setWindow();
    await startPlan();
    clock.current = DateTime(2026, 10, 29, 23, 29);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('About one every 1 min until bed'), findsOneWidget);
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
    expect(find.text('Next one on schedule in 120 min'), findsOneWidget);
    await tester.disposeApp();
  });

  group('nothing to pace', () {
    Future<void> expectNoLine(WidgetTester tester) async {
      await tester.pumpAppPastSplash(height: 2400);
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
      await expectNoLine(tester);
    });

    testWidgets('on quit day', (tester) async {
      await setWindow();
      await seedHabit(
        PlanDraft(startDay: today.addDays(-14), startLimit: 8, quitDay: today),
      );
      await expectNoLine(tester);
    });

    testWidgets('before wake', (tester) async {
      await setWindow();
      await startPlan();
      clock.current = DateTime(2026, 10, 29, 6);
      await expectNoLine(tester);
    });
  });

  testWidgets('without a day window, the prompt sets one', (tester) async {
    await startPlan();
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.text(prompt), findsOneWidget);

    await tester.scrollAndTap(find.text(prompt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(prompt), findsNothing);
    expect(find.textContaining('About one every'), findsOneWidget);
    final stored = await tester.runAsync(() => sl<SettingsRepository>().get());
    final settings = (stored! as Success<AppSettings>).value;
    expect(settings.wakeMinute, 450);
    expect(settings.bedMinute, 1410);
    await tester.disposeApp();
  });
}
