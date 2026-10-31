import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 16),
        startLimit: 9,
        quitDay: LogicalDay(2026, 10, 16).addDays(63),
      ),
    );
  });

  tearDown(InjectionContainer.reset);

  bool glassOn(WidgetTester tester) =>
      GlassMode.of(tester.element(find.byType(HomePage, skipOffstage: false)));

  testWidgets('floating tab bar switches tabs by icon', (tester) async {
    await tester.pumpAppPastSplash();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.bySemanticsLabel('Home'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('glass is on unless Reduce Transparency is', (tester) async {
    await tester.pumpAppPastSplash();
    expect(glassOn(tester), isTrue);
    expect(find.text('Glass effects'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('the + button logs, and long-press opens the log menu', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);
    await tester.tap(find.text('Save without trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await tester.longPress(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Log now'), findsOneWidget);
    expect(find.text('Add a missed log'), findsOneWidget);
    expect(find.text('Add a habit'), findsOneWidget);

    await tester.tap(find.text('Add a missed log'));
    await tester.pumpAndSettle();
    expect(find.text('Log now'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close'), findsNothing);

    await tester.disposeApp();
  });

  // The menu reads today's counts from drift before it opens, so real time
  // has to pass between fake-clock pumps.
  Future<void> tapLogAndWaitForMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Log'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  group('with two habits', () {
    setUp(() async {
      await seedHabit(
        PlanDraft(
          startDay: LogicalDay(2026, 10, 16),
          startLimit: 5,
          quitDay: LogicalDay(2026, 10, 16).addDays(63),
        ),
        habit: Habit.vaping,
      );
      await sl<HabitLogRepository>().addLog(
        habitId: 1,
        loggedAt: DateTime(2026, 10, 16, 9),
      );
    });

    testWidgets("tap opens the menu listing both with today's counts", (
      tester,
    ) async {
      await tester.pumpAppPastSplash(height: 2400);

      await tapLogAndWaitForMenu(tester);

      expect(find.widgetWithText(InkWell, '1 of 9 today'), findsOneWidget);
      expect(find.widgetWithText(InkWell, '0 of 5 today'), findsOneWidget);
      expect(find.text('Add a missed log'), findsOneWidget);
      expect(find.text('Add a habit'), findsOneWidget);
      expect(find.text('What triggered this one?'), findsNothing);

      await tester.tap(find.text('Add a missed log'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.disposeApp();
    });

    testWidgets('menu habit opens its trigger sheet', (tester) async {
      await tester.pumpAppPastSplash(height: 2400);

      await tapLogAndWaitForMenu(tester);
      await tester.tap(find.widgetWithText(InkWell, '0 of 5 today'));
      await tester.pumpAndSettle();

      expect(find.text('What triggered this one?'), findsOneWidget);

      await tester.tap(find.text('Save without trigger'));
      await tester.pumpAndSettle();
      await tester.disposeApp();
    });
  });

  group('hold hint', () {
    setUp(() async {
      final repository = sl<SettingsRepository>();
      final current = await repository.get() as Success<AppSettings>;
      await repository.save(current.value.copyWith(logHintSeen: false));
    });

    Future<void> saveLog(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save without trigger'));
      await tester.pumpInSteps(const Duration(milliseconds: 900));
    }

    // The hint waits for the 2 s Undo snackbar to close.
    Future<void> logOnce(WidgetTester tester) async {
      await saveLog(tester);
      await tester.pumpInSteps(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    Future<bool> hintSeen(WidgetTester tester) async {
      final settings = await tester.runAsync(
        () => sl<SettingsRepository>().get(),
      );
      return (settings! as Success<AppSettings>).value.logHintSeen;
    }

    testWidgets('hint shows once after the first log', (tester) async {
      await tester.pumpAppPastSplash(height: 2400);
      expect(find.text('Hold + for more'), findsNothing);

      await saveLog(tester);
      expect(find.text('Hold + for more'), findsNothing);
      await tester.pumpInSteps(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Hold + for more'), findsOneWidget);
      expect(
        find.text('Add a missed log, or start tracking another habit.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      await logOnce(tester);
      expect(find.text('Hold + for more'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('Got it hides it for good', (tester) async {
      await tester.pumpAppPastSplash(height: 2400);
      await logOnce(tester);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Hold + for more'), findsNothing);
      expect(await hintSeen(tester), isTrue);

      await tester.disposeApp();
    });

    testWidgets('the first log can be undone, and the hint waits', (
      tester,
    ) async {
      await tester.pumpAppPastSplash(height: 2400);
      await saveLog(tester);

      await tester.tap(find.text('Undo'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpInSteps(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Hold + for more'), findsNothing);
      expect(await hintSeen(tester), isFalse);
      final logs = await tester.runAsync(
        () => sl<HabitLogRepository>().watchRecent(limit: 10).first,
      );
      expect(logs, isEmpty);

      await logOnce(tester);
      expect(find.text('Hold + for more'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      await tester.disposeApp();
    });
  });

  testWidgets('sheets float above the tab bar on the root navigator', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.byTooltip('Log'));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.text('What triggered this one?'));
    final tabBar = tester.getRect(find.byTooltip('Home'));
    expect(find.text('What triggered this one?'), findsOneWidget);
    // The sheet is a root route, so it is painted over the tab bar area.
    expect(sheet.top, lessThan(tabBar.top));

    await tester.tap(find.text('Save without trigger'));
    await tester.pumpAndSettle();
    await tester.disposeApp();
  });
}
