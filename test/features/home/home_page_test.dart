import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);

  setUp(() => setUpTestDependencies(FixedClock(now)));
  tearDown(InjectionContainer.reset);

  Future<void> startPlan(LogicalDay start, {int limit = 9}) => sl<SavePlan>()(
    PlanDraft(
      startDay: start,
      startLimit: limit,
      quitDay: start.addDays(limit * 7),
    ),
  );

  Future<void> logOn(DateTime at, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      await sl<LogSmoke>()(
        LogSmokeInput(loggedAt: at.add(Duration(minutes: i))),
      );
    }
  }

  String countText(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('today-count')))
      .textSpan!
      .toPlainText();

  Future<List<SmokeTrigger?>> storedTriggers(WidgetTester tester) async {
    final logs = await tester.runAsync(
      () => sl<SmokeLogRepository>()
          .watchLogs(from: DateTime(2026), to: DateTime(2027))
          .first,
    );
    return logs!.map((log) => log.trigger).toList();
  }

  testWidgets('first day: empty state, stage and next drop', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '0 / 9');
    expect(find.text('9 left today'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(find.text('No smokes logged today. Nice start.'), findsOneWidget);
    expect(find.text('Stage 1 of 9 · Daily limit: 9'), findsOneWidget);
    expect(find.text('Plan started today'), findsOneWidget);
    expect(find.text('Drops to 8 in 7d'), findsOneWidget);
    expect(find.text('D1'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('logging asks for a trigger and stores it', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    await tester.tap(find.text('Save with trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(countText(tester), '1 / 9');
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
    expect(await storedTriggers(tester), [SmokeTrigger.coffee]);

    await tester.disposeApp();
  });

  testWidgets('skipping the trigger still logs', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip and save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(countText(tester), '1 / 9');
    expect(await storedTriggers(tester), [null]);

    await tester.disposeApp();
  });

  testWidgets('dismissing the trigger sheet logs nothing', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '0 / 9');
    expect(await storedTriggers(tester), isEmpty);

    await tester.disposeApp();
  });

  testWidgets('the first log offers to stop asking for triggers', (
    tester,
  ) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Ask every time'), findsOneWidget);

    await tester.tap(find.text('Ask every time'));
    await tester.pump();
    await tester.tap(find.text('Skip and save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(countText(tester), '1 / 9');

    // Asking is now off: the next log saves straight away.
    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '2 / 9');

    await tester.disposeApp();
  });

  testWidgets('later logs ask without the offer', (tester) async {
    await startPlan(today);
    await sl<SaveSettings>()(const AppSettings(triggerPromptIntroSeen: true));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);
    expect(find.text('Ask every time'), findsNothing);

    await tester.tap(find.text('Skip and save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(countText(tester), '1 / 9');

    await tester.disposeApp();
  });

  testWidgets('with asking turned off a log saves in one tap', (tester) async {
    await startPlan(today);
    await sl<SaveSettings>()(const AppSettings(askForTrigger: false));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '1 / 9');
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('over the limit shows the overflow state', (tester) async {
    await startPlan(today, limit: 3);
    await logOn(DateTime(2026, 10, 16, 9), times: 5);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '5 / 3');
    expect(find.text('Over limit'), findsOneWidget);
    expect(find.text('2 over limit'), findsOneWidget);
    expect(find.text('167% of daily limit'), findsOneWidget);
    expect(find.text('6h 38m'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('chart summarises the week and switches to month', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 14, 9), times: 6);
    await logOn(DateTime(2026, 10, 15, 9), times: 11);
    await logOn(DateTime(2026, 10, 16, 9), times: 4);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Smoking History'));
    await tester.pumpAndSettle();
    expect(find.text('Avg 7.0/day'), findsOneWidget);
    expect(find.text('1 day over'), findsOneWidget);
    expect(find.text('2 days within limit'), findsOneWidget);
    expect(find.text('Limit 9'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Avg 7.0/day'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.disposeApp();
  });

  testWidgets('tapping a bar opens the day, where a log can be deleted', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 15, 9), times: 2);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Smoking History'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Thursday, Oct 15: 2 of 9'));
    await tester.pumpAndSettle();

    expect(find.text('Day Detail'), findsOneWidget);
    expect(find.text('2 of 9 logged'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 9 logged'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a missed log can be added from the day sheet', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 15, 9));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Smoking History'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Thursday, Oct 15: 1 of 9'));
    await tester.pumpAndSettle();
    await tester.scrollAndTap(find.text('Add missed log'));
    await tester.pumpAndSettle();

    expect(find.text('12:00 PM'), findsOneWidget);
    await tester.scrollAndTap(find.text('Add log'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 9 logged'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('stats reflect completed days and pack price', (tester) async {
    await sl<SaveSettings>()(const AppSettings(packPriceCents: 1450));
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 14, 9), times: 6);
    await logOn(DateTime(2026, 10, 15, 9), times: 6);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Money saved'));
    await tester.pumpAndSettle();
    expect(find.text('3 Days'), findsOneWidget);
    expect(find.text('↓ 33%'), findsOneWidget);
    expect(find.text(r'$4.35'), findsOneWidget);
    expect(find.text('6 smokes'), findsOneWidget);
    expect(find.text('D3'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('counts down to quit day on the last stage', (tester) async {
    await sl<SavePlan>()(
      PlanDraft(
        startDay: today.addDays(-10),
        startLimit: 3,
        quitDay: today.addDays(3),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Quit day in 3d'), findsOneWidget);
    expect(find.text('Stage 3 of 3 · Daily limit: 1'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('after the quit date the limit is 0 and the day is smoke-free', (
    tester,
  ) async {
    await sl<SavePlan>()(
      PlanDraft(
        startDay: today.addDays(-20),
        startLimit: 4,
        quitDay: today.addDays(-2),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '0 / 0');
    expect(find.text('Smoke-free day'), findsOneWidget);
    expect(find.text('Smoke-free since Oct 14'), findsOneWidget);
    expect(find.text('QUIT'), findsOneWidget);

    await tester.disposeApp();
  });
}
