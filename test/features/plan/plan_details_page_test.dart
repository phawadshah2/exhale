import 'dart:async';

import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/presentation/pages/plan_details_page.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/current_stage_card.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_days.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_row.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Frame K: 12 a day from 8 Oct to 31 Dec, 12 stages of 7 days. Today is day
  // 4 of stage 4 (29 Oct to 4 Nov).
  final start = LogicalDay(2026, 10, 8);
  final quit = LogicalDay(2026, 12, 31);
  final today = LogicalDay(2026, 11, 1);
  const title = 'You are here. Regrettably.';
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late FixedClock clock;

  setUp(() {
    clock = FixedClock(DateTime(2026, 11, 1, 15));
    return setUpTestDependencies(clock);
  });
  tearDown(InjectionContainer.reset);

  /// 20 to a pack at 800 cents is 40 cents a session.
  Future<void> seedK({Habit habit = Habit.vaping, int? priceCents = 800}) =>
      seedHabit(
        PlanDraft(startDay: start, startLimit: 12, quitDay: quit),
        habit: habit,
        priceCents: priceCents,
      );

  Future<void> logOn(LogicalDay day, {int times = 1, Trigger? trigger}) async {
    for (var i = 0; i < times; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: DateTime(day.year, day.month, day.day, 9, i),
          trigger: trigger,
        ),
      );
    }
  }

  Future<void> openDetails(WidgetTester tester) async {
    await tester.pumpAppPastSplash(height: 2400);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(AppRoutes.planDetailsFor(1)));
    await tester.pumpAndSettle();
  }

  Future<void> setDayWindow() async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
    );
  }

  group('entry', () {
    testWidgets("tapping Home's plan card opens the page", (tester) async {
      await seedK();
      await tester.pumpAppPastSplash(height: 2400);

      await tester.tap(find.text('Your plan'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('the plan card has no Edit pill', (tester) async {
      await seedK();
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.text('Your plan'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('the plan card is named for VoiceOver', (tester) async {
      await seedK();
      final semantics = tester.ensureSemantics();
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.bySemanticsLabel('Plan details'), findsOneWidget);
      semantics.dispose();
      await tester.disposeApp();
    });

    testWidgets("the page's Edit pill opens Edit plan", (tester) async {
      await seedK();
      await openDetails(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit plan'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('Back returns Home', (tester) async {
      await seedK();
      await openDetails(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(find.text('Your plan'), findsOneWidget);
      await tester.disposeApp();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('the whole plan', () {
    testWidgets('shows every tile and the line under them', (tester) async {
      await seedK();
      await logOn(today.addDays(-1), times: 5);
      await logOn(today, times: 2);
      await openDetails(tester);

      expect(find.text('The whole plan'), findsOneWidget);
      expect(find.text('Sessions used'), findsOneWidget);
      expect(find.text('7 / 546', findRichText: true), findsOneWidget);
      expect(find.text('Sessions avoided'), findsOneWidget);
      expect(find.text('283 / 462', findRichText: true), findsOneWidget);
      expect(find.text('Money saved'), findsOneWidget);
      expect(
        find.text(r'$113.20 / $184.80', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Days kept'), findsOneWidget);
      expect(find.text('24 / 24', findRichText: true), findsOneWidget);
      expect(
        find.text(
          r'Without a plan: 1,008 sessions and $403.20. '
          'Nobody said it was cheap.',
        ),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('a no-cost habit has three tiles and the short line', (
      tester,
    ) async {
      await seedK(habit: Habit.socialMedia, priceCents: null);
      await openDetails(tester);

      expect(find.text('Money saved'), findsNothing);
      expect(
        find.text('Without a plan: 1,008 sessions. Nobody said it was cheap.'),
        findsOneWidget,
      );
      expect(find.textContaining(r'$'), findsNothing);

      // The last tile takes the row.
      expect(
        tester.getTopLeft(find.text('Days kept')).dx,
        tester.getTopLeft(find.text('Sessions used')).dx,
      );
      expect(
        tester.getTopLeft(find.text('Days kept')).dy,
        greaterThan(tester.getTopLeft(find.text('Sessions avoided')).dy),
      );
      await tester.disposeApp();
    });

    testWidgets('a cost habit with no price offers to add one', (tester) async {
      await seedK(priceCents: null);
      await openDetails(tester);

      expect(find.text('Money saved'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(
        find.text('Without a plan: 1,008 sessions. Nobody said it was cheap.'),
        findsOneWidget,
      );
      expect(find.textContaining(r'$'), findsNothing);

      await tester.tap(find.text('Add a price ›'));
      await tester.pumpAndSettle();
      expect(find.text('Edit plan'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('a new log shows without leaving the page', (tester) async {
      await seedK();
      await openDetails(tester);
      expect(find.text('0 / 546', findRichText: true), findsOneWidget);

      await tester.runAsync(() => logOn(today));
      await tester.pumpAndSettle();

      expect(find.text('1 / 546', findRichText: true), findsOneWidget);
      await tester.disposeApp();
    });
  });

  group('sections', () {
    testWidgets('headers carry their side text', (tester) async {
      await seedK();
      await openDetails(tester);

      expect(find.text('BEHIND YOU'), findsOneWidget);
      expect(find.text(r'$100.80 saved'), findsOneWidget);
      expect(find.text('YOU, REGRETTABLY'), findsOneWidget);
      expect(find.text('Stage 4 of 12'), findsOneWidget);
      expect(find.text('AHEAD OF YOU'), findsOneWidget);
      expect(find.text(r'$168.00 to save'), findsOneWidget);
      expect(find.text('This plan'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('a section with no stages is hidden', (tester) async {
      await seedHabit(
        PlanDraft(startDay: today, startLimit: 12, quitDay: quit),
      );
      await openDetails(tester);

      expect(find.text('BEHIND YOU'), findsNothing);
      expect(find.text('YOU, REGRETTABLY'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('a replan labels the earlier stages and this plan', (
      tester,
    ) async {
      await seedK();
      await sl<PlanRepository>().savePlan(
        1,
        ReductionPlan(
          startDay: LogicalDay(2026, 10, 20),
          startLimit: 8,
          quitDay: quit,
        ),
      );
      await openDetails(tester);

      expect(find.text('Earlier plan · until Oct 19'), findsOneWidget);
      expect(find.text('This plan'), findsOneWidget);
      // The cut-off stage ends the day before the new plan.
      expect(find.text('Oct 15 – 19'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('stages show dates and money, and the current its share', (
      tester,
    ) async {
      await seedK();
      await openDetails(tester);

      expect(find.text('Oct 8 – 14'), findsOneWidget);
      expect(find.text(r'$33.60'), findsNWidgets(3));
      expect(find.text('saved'), findsNWidgets(3));
      expect(find.text('Oct 29 – Nov 4 · day 4 of 7'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text(r'of $8.40'), findsOneWidget);
      expect(find.text(r'$11.20'), findsOneWidget);
      expect(find.text('to save'), findsNWidgets(8));
      await tester.disposeApp();
    });

    testWidgets('a current stage at the baseline has nothing to save of', (
      tester,
    ) async {
      // Day 3 of stage 1, at 12 a day: the limit is still the baseline.
      await seedHabit(
        PlanDraft(startDay: today.addDays(-2), startLimit: 12, quitDay: quit),
        habit: Habit.vaping,
        priceCents: 800,
      );
      await logOn(today.addDays(-2), times: 4);
      await openDetails(tester);

      // (12 − 4 + 12) × 40 cents.
      final shown = find.text(r'of $0.00').evaluate().length;
      final saved = find.text('saved').evaluate().length;
      expect(find.text(r'$8.00'), findsWidgets);
      await tester.disposeApp();
      expect(shown, 0);
      expect(saved, 1);
    });
  });

  group('rings', () {
    StageRingPainter painterOf(WidgetTester tester, Finder ring) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(of: ring, matching: find.byType(CustomPaint)),
                )
                .painter!
            as StageRingPainter;

    testWidgets('fill is used over allowed, capped, and red when over', (
      tester,
    ) async {
      await seedK();
      await logOn(start, times: 90);
      await logOn(start.addDays(7), times: 21);
      await openDetails(tester);

      expect(find.byType(StageRing), findsNWidgets(12));
      final context = tester.element(find.byType(StageRing).first);

      final over = painterOf(tester, find.byType(StageRing).at(0));
      expect(over.fill, 1);
      expect(over.color, context.exhale.danger.solid);

      final under = painterOf(tester, find.byType(StageRing).at(1));
      expect(under.fill, closeTo(21 / 77, 0.001));
      expect(under.color, context.exhale.success.solid);
      await tester.disposeApp();
    });

    testWidgets('a stage used exactly to its limit is amber', (tester) async {
      await seedK();
      await logOn(start, times: 84);
      await openDetails(tester);

      final context = tester.element(find.byType(StageRing).first);
      final atLimit = painterOf(tester, find.byType(StageRing).at(0));
      expect(atLimit.fill, 1);
      expect(atLimit.color, context.exhale.warning.solid);
      await tester.disposeApp();
    });

    testWidgets('a stage ahead has a dashed track and no fill', (tester) async {
      await seedK();
      await openDetails(tester);

      final ahead = painterOf(tester, find.byType(StageRing).last);
      expect(ahead.dashed, isTrue);
      expect(ahead.fill, 0);
      await tester.disposeApp();
    });

    testWidgets('rings fade in', (tester) async {
      await seedK();
      await openDetails(tester);

      expect(find.byType(FillIn), findsWidgets);
      await tester.disposeApp();
    });

    testWidgets('Reduce Motion removes the fade', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await seedK();
      await openDetails(tester);

      expect(find.byType(StageRing), findsWidgets);
      expect(find.byType(FillIn), findsNothing);
      await tester.disposeApp();
    });
  });

  group('stage rows', () {
    testWidgets('stages open and close independently', (tester) async {
      await seedK();
      await logOn(start, times: 13, trigger: Trigger.stress);
      await openDetails(tester);

      expect(find.text('Days over'), findsNothing);

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('13 of 84 used'), findsOneWidget);
      expect(find.text('1 of 7'), findsOneWidget);
      expect(find.text('1.9 a day'), findsOneWidget);
      expect(find.text('Mostly'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);
      expect(find.text('The easy one. It was meant to be.'), findsOneWidget);

      await tester.tap(find.text('Stage 2'));
      await tester.pumpAndSettle();
      expect(find.text('Days over'), findsNWidgets(2));
      // Nothing logged in stage 2, so it has no top trigger.
      expect(find.text('Mostly'), findsOneWidget);
      expect(
        find.text('Your best so far. Try not to let it go to your head.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();
      expect(find.text('Days over'), findsOneWidget);
      expect(find.text('13 of 84 used'), findsNothing);
      expect(find.text('0 of 77 used'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets("a stage's over figures are red", (tester) async {
      await seedK();
      await logOn(start, times: 90);
      await openDetails(tester);

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();

      final danger = tester
          .element(find.text('90 of 84 used'))
          .exhale
          .danger
          .foreground;
      expect(
        tester.widget<Text>(find.text('90 of 84 used')).style?.color,
        danger,
      );
      expect(tester.widget<Text>(find.text('1 of 7')).style?.color, danger);
      await tester.disposeApp();
    });

    testWidgets('a past stage shows a ring per day, with no today', (
      tester,
    ) async {
      await seedK();
      await logOn(start, times: 13);
      await openDetails(tester);

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();

      final rings = find.descendant(
        of: find.byType(StageRow).first,
        matching: find.byType(StageDayRing),
      );
      expect(rings, findsNWidgets(7));
      final days = tester.widgetList<StageDayRing>(rings).toList();
      expect(days.first.day, start);
      expect(days.last.day, start.addDays(6));
      expect(days.any((ring) => ring.isToday), isFalse);
      expect(days.every((ring) => ring.progress != null), isTrue);
      expect(days.first.progress!.count, 13);
      await tester.disposeApp();
    });

    testWidgets('a 15-day past stage shows its dots and both dates', (
      tester,
    ) async {
      final planStart = today.addDays(-20);
      await seedHabit(
        PlanDraft(
          startDay: planStart,
          startLimit: 2,
          quitDay: planStart.addDays(30),
        ),
        habit: Habit.vaping,
        priceCents: 800,
      );
      await logOn(planStart, times: 3);
      await openDetails(tester);

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();

      final row = find.byType(StageRow).first;
      expect(
        find.descendant(of: row, matching: find.byType(StageDayRing)),
        findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.text('Oct 12')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Oct 26')),
        findsOneWidget,
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: row,
                      matching: find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is DayDotsPainter,
                      ),
                    ),
                  )
                  .painter!
              as DayDotsPainter;
      expect(painter.dots, hasLength(15));
      expect(painter.dots.first, DayDot.over);
      expect(painter.dots.skip(1), everyElement(DayDot.under));
      await tester.disposeApp();
    });

    testWidgets('a future stage shows its pace and what to avoid', (
      tester,
    ) async {
      await seedK();
      await setDayWindow();
      await openDetails(tester);

      await tester.tap(find.text('Stage 5'));
      await tester.pumpAndSettle();

      expect(find.text('56 allowed'), findsOneWidget);
      expect(find.text('One every 2 h'), findsOneWidget);
      expect(find.text('28 sessions'), findsOneWidget);
      expect(find.text('In 4 days'), findsOneWidget);
      expect(
        find.text('One fewer. You have survived worse Mondays.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('with no day window, Pace is hidden', (tester) async {
      await seedK();
      await openDetails(tester);

      await tester.tap(find.text('Stage 5'));
      await tester.pumpAndSettle();

      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Pace'), findsNothing);
      expect(find.textContaining('One every'), findsNothing);
      await tester.disposeApp();
    });

    testWidgets('the next stage starts Tomorrow', (tester) async {
      clock.current = DateTime(2026, 11, 4, 15);
      await seedK();
      await openDetails(tester);

      await tester.tap(find.text('Stage 5'));
      await tester.pumpAndSettle();

      expect(find.text('Tomorrow'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('a limit of one on the default window is one every 16 h', (
      tester,
    ) async {
      await seedHabit(
        PlanDraft(startDay: today, startLimit: 2, quitDay: today.addDays(14)),
      );
      await setDayWindow();
      await openDetails(tester);

      await tester.tap(find.text('Stage 2'));
      await tester.pumpAndSettle();

      expect(find.text('One every 16 h'), findsOneWidget);
      expect(find.text('The last one. Literally.'), findsOneWidget);
      await tester.disposeApp();
    });
  });

  group('finish', () {
    testWidgets('the row counts down to the quit date', (tester) async {
      await seedK();
      await openDetails(tester);

      expect(find.text('Vape-free from Dec 31'), findsOneWidget);
      expect(
        find.text('60 days to go. Then this ring stays full.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('one day to go is singular', (tester) async {
      await seedHabit(
        PlanDraft(
          startDay: LogicalDay(2026, 10, 20),
          startLimit: 4,
          quitDay: today.addDays(1),
        ),
      );
      await openDetails(tester);

      expect(
        find.text('1 day to go. Then this ring stays full.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('from the quit date every stage is behind you', (tester) async {
      await seedHabit(
        PlanDraft(
          startDay: LogicalDay(2026, 9, 1),
          startLimit: 4,
          quitDay: today,
        ),
      );
      await openDetails(tester);

      expect(find.text('You made it. Regrettably.'), findsOneWidget);
      expect(find.text(title), findsNothing);
      expect(find.text('BEHIND YOU'), findsOneWidget);
      expect(find.text('YOU, REGRETTABLY'), findsNothing);
      expect(find.text('AHEAD OF YOU'), findsNothing);
      expect(find.text('You reached your quit date'), findsOneWidget);
      await tester.disposeApp();
    });
  });

  group('the current stage', () {
    final stageStart = LogicalDay(2026, 10, 25);

    /// 2 a day for [days], then 1 a day for [days]. Today is day 8.
    Future<void> seedStage(int days) => seedHabit(
      PlanDraft(
        startDay: stageStart,
        startLimit: 2,
        quitDay: stageStart.addDays(days * 2),
      ),
      habit: Habit.vaping,
      priceCents: 800,
    );

    Future<void> logResults() async {
      await logOn(stageStart, times: 3);
      await logOn(stageStart.addDays(1), times: 2);
      await logOn(stageStart.addDays(2));
      await logOn(today);
    }

    Finder ringAt(int index) => find.byType(StageDayRing).at(index);

    StageRingPainter dayPainter(WidgetTester tester, int index) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: ringAt(index),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as StageRingPainter;

    testWidgets('14 days shows a ring per day, coloured by result', (
      tester,
    ) async {
      await seedStage(14);
      await logResults();
      await openDetails(tester);

      expect(find.byType(StageDayRing), findsNWidgets(14));
      expect(find.text('Each dot is a day'), findsNothing);
      expect(find.text('Oct 25 – Nov 7 · day 8 of 14'), findsOneWidget);

      final context = tester.element(find.byType(StageDayRing).first);
      final over = dayPainter(tester, 0);
      expect(over.color, context.exhale.danger.solid);
      expect(over.fill, 1);
      expect(
        find.descendant(of: ringAt(0), matching: find.text('3')),
        findsOneWidget,
      );
      expect(dayPainter(tester, 1).color, context.exhale.warning.solid);
      final under = dayPainter(tester, 2);
      expect(under.color, context.exhale.success.solid);
      expect(under.fill, 0.5);
      await tester.disposeApp();
    });

    testWidgets('today stands out and is coloured the same way', (
      tester,
    ) async {
      await seedStage(14);
      await logResults();
      await openDetails(tester);

      final context = tester.element(find.byType(StageDayRing).first);
      expect(dayPainter(tester, 7).color, context.exhale.success.solid);
      expect(dayPainter(tester, 7).dashed, isFalse);
      expect(tester.widget<StageDayRing>(ringAt(7)).isToday, isTrue);
      expect(tester.widget<StageDayRing>(ringAt(6)).isToday, isFalse);

      final weekday = find.descendant(
        of: ringAt(7),
        matching: find.text('Sun'),
      );
      expect(tester.widget<Text>(weekday).style?.fontWeight, FontWeight.w800);
      await tester.disposeApp();
    });

    testWidgets('a day ahead has a dashed track and its limit inside', (
      tester,
    ) async {
      await seedStage(14);
      await logResults();
      await openDetails(tester);

      final ahead = dayPainter(tester, 8);
      expect(ahead.dashed, isTrue);
      expect(ahead.fill, 0);
      expect(
        find.descendant(of: ringAt(8), matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ringAt(8), matching: find.text('Mon')),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('15 days shows a dot per day and both dates', (tester) async {
      await seedStage(15);
      await logResults();
      await openDetails(tester);

      expect(find.byType(StageDayRing), findsNothing);
      expect(find.text('Each dot is a day'), findsOneWidget);
      expect(find.text('Oct 25'), findsOneWidget);
      expect(find.text('Nov 8'), findsOneWidget);

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint &&
                          widget.painter is DayDotsPainter,
                    ),
                  )
                  .painter!
              as DayDotsPainter;
      expect(painter.dots, hasLength(15));
      expect(painter.dots[0], DayDot.over);
      expect(painter.dots[1], DayDot.atLimit);
      expect(painter.dots[2], DayDot.under);
      expect(painter.dots[3], DayDot.under);
      expect(painter.dots[7], DayDot.today);
      expect(painter.dots[8], DayDot.ahead);
      expect(painter.layout.cols, 13);
      expect(
        painter.under,
        tester.element(find.text('Each dot is a day')).exhale.success.solid,
      );
      await tester.disposeApp();
    });

    testWidgets("today's dot has no result even once it is over", (
      tester,
    ) async {
      await seedStage(15);
      await logOn(today, times: 3);
      await openDetails(tester);

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint &&
                          widget.painter is DayDotsPainter,
                    ),
                  )
                  .painter!
              as DayDotsPainter;
      expect(painter.dots[7], DayDot.today);
      expect(find.text('3 of 30 used · 1 day over'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('the footer counts today once it has gone over', (
      tester,
    ) async {
      await seedStage(14);
      await logOn(stageStart, times: 3);
      await logOn(today, times: 3);
      await openDetails(tester);

      expect(find.text('6 of 28 used · 2 days over'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('the key names the three results', (tester) async {
      await seedK();
      await openDetails(tester);

      expect(find.text('Under'), findsOneWidget);
      expect(find.text('At limit'), findsOneWidget);
      expect(find.text('Over'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('it says when the limit drops', (tester) async {
      await seedK();
      await openDetails(tester);

      expect(
        find.text('Drops to 8 in 4 days. Try to look surprised.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets("on the stage's last day it drops tomorrow", (tester) async {
      clock.current = DateTime(2026, 11, 4, 15);
      await seedK();
      await openDetails(tester);

      expect(
        find.text('Drops to 8 tomorrow. Try to look surprised.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('on the last stage it drops to 0', (tester) async {
      clock.current = DateTime(2026, 12, 28, 15);
      await seedK();
      await openDetails(tester);

      expect(
        find.text('Drops to 0 in 3 days. Try to look surprised.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('a drop of two names the real next limit', (tester) async {
      // 18 today and 16 tomorrow.
      await seedHabit(
        PlanDraft(
          startDay: today.addDays(-2),
          startLimit: 20,
          quitDay: today.addDays(12),
        ),
      );
      await openDetails(tester);

      expect(
        find.text('Drops to 16 tomorrow. Try to look surprised.'),
        findsOneWidget,
      );
      await tester.disposeApp();
    });

    testWidgets('the days are summed up for VoiceOver', (tester) async {
      await seedStage(14);
      await logResults();
      final semantics = tester.ensureSemantics();
      await openDetails(tester);

      expect(
        find.bySemanticsLabel('14 days, limit 2. 1 over. Today is day 8.'),
        findsOneWidget,
      );
      semantics.dispose();
      await tester.disposeApp();
    });

    testWidgets('the current stage has no chevron', (tester) async {
      await seedK();
      await openDetails(tester);

      // One for each of the other 11 stages.
      expect(find.byIcon(AppIcons.chevronDown), findsNWidgets(11));
      await tester.disposeApp();
    });

    group('a day opens its logs', () {
      LogsQuery? openedQuery(WidgetTester tester) {
        final page = find.byType(LogsPage);
        return page.evaluate().isEmpty
            ? null
            : tester.widget<LogsPage>(page).query;
      }

      Finder currentRing(int index) => find
          .descendant(
            of: find.byType(CurrentStageCard),
            matching: find.byType(StageDayRing),
          )
          .at(index);

      testWidgets('from a past ring', (tester) async {
        await seedK();
        await openDetails(tester);
        await tester.tap(find.text('Stage 1'));
        await tester.pumpAndSettle();

        await tester.tap(
          find
              .descendant(
                of: find.byType(StageRow).first,
                matching: find.byType(StageDayRing),
              )
              .at(2),
        );
        await tester.pumpAndSettle();

        final day = start.addDays(2);
        expect(openedQuery(tester), LogsQuery(habitId: 1, from: day, to: day));
        await tester.disposeApp();
      });

      testWidgets('from a current ring, but not one ahead', (tester) async {
        await seedK();
        await openDetails(tester);

        await tester.tap(currentRing(5));
        await tester.pumpAndSettle();
        expect(openedQuery(tester), isNull);

        await tester.tap(currentRing(1));
        await tester.pumpAndSettle();
        final day = LogicalDay(2026, 10, 30);
        expect(openedQuery(tester), LogsQuery(habitId: 1, from: day, to: day));
        await tester.disposeApp();
      });

      testWidgets('from a dot', (tester) async {
        await seedStage(15);
        await openDetails(tester);

        final dots = find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is DayDotsPainter,
        );
        final layout =
            (tester.widget<CustomPaint>(dots).painter! as DayDotsPainter)
                .layout;
        final box = tester.getRect(dots);
        final across = (box.width - layout.size) / (layout.cols - 1);
        await tester.tapAt(
          box.topLeft + Offset(2 * across + layout.size / 2, layout.size / 2),
        );
        await tester.pumpAndSettle();

        final day = stageStart.addDays(2);
        expect(openedQuery(tester), LogsQuery(habitId: 1, from: day, to: day));
        await tester.disposeApp();
      });

      testWidgets('a ring is a VoiceOver button', (tester) async {
        await seedK();
        final semantics = tester.ensureSemantics();
        await openDetails(tester);

        expect(
          tester.getSemantics(currentRing(1)),
          isSemantics(
            label: 'Friday, Oct 30: 0 of 9',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(currentRing(5)),
          isSemantics(isButton: false, hasTapAction: false),
        );
        semantics.dispose();
        await tester.disposeApp();
      });
    });
  });

  testWidgets('a failed plan read shows an error and can retry', (
    tester,
  ) async {
    await seedK();
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await startupOverrides(),
          planHistoryProvider.overrideWith((ref, habitId) {
            attempts++;
            return attempts == 1
                ? Stream.error(StateError('storage'))
                : const Stream.empty();
          }),
        ],
        child: const MaterialApp(home: PlanDetailsPage(habitId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load your plan."), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load your plan."), findsNothing);
    expect(attempts, 2);
    await tester.disposeApp();
  });

  group('VoiceOver', () {
    Future<void> expectTapAction(
      WidgetTester tester,
      Pattern label,
      SemanticsHandle handle,
    ) async {
      try {
        expect(
          find.semantics.byLabel(label).evaluate().single,
          isSemantics(hasTapAction: true),
        );
      } finally {
        handle.dispose();
        await tester.disposeApp();
      }
    }

    testWidgets('can open a stage', (tester) async {
      final handle = tester.ensureSemantics();
      await seedK();
      await openDetails(tester);

      await expectTapAction(tester, RegExp('^Stage 1, '), handle);
    });

    testWidgets('can add a price from its tile', (tester) async {
      final handle = tester.ensureSemantics();
      await seedK(priceCents: null);
      await openDetails(tester);

      await expectTapAction(tester, RegExp('^Money saved, '), handle);
    });

    testWidgets('can press Edit', (tester) async {
      final handle = tester.ensureSemantics();
      await seedK();
      await openDetails(tester);

      await expectTapAction(tester, 'Edit plan', handle);
    });
  });

  group('at 3x text on an SE width', () {
    setUpAll(loadAppFonts);
    setUp(() {
      binding.platformDispatcher.textScaleFactorTestValue = 3;
    });
    tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);

    for (final (name, stageDays) in const [
      ('a 365-day current stage', 365),
      ('a 14-day current stage', 14),
    ]) {
      testWidgets('$name stays whole', (tester) async {
        await seedHabit(
          PlanDraft(
            startDay: today.addDays(-7),
            startLimit: 2,
            quitDay: today.addDays(-7 + stageDays * 2),
          ),
          habit: Habit.vaping,
          priceCents: 800,
        );
        await openDetails(tester);
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        await tester.pumpAndSettle();

        expect(find.text('NOW'), findsOneWidget);

        final clipped = tester.clippedTexts(
          within: find.byType(PlanDetailsPage),
        );
        await tester.disposeApp();
        expect(clipped, isEmpty);
      });
    }

    testWidgets('80 stages stay whole', (tester) async {
      await seedHabit(
        PlanDraft(
          startDay: LogicalDay(2026, 8, 1),
          startLimit: 80,
          quitDay: LogicalDay(2026, 8, 1).addDays(560),
        ),
        habit: Habit.vaping,
        priceCents: 800,
      );
      await setDayWindow();
      await openDetails(tester);
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      await tester.pumpAndSettle();

      expect(find.byType(StageRing), findsNWidgets(80));

      await tester.scrollAndTap(find.text('Stage 1'));
      await tester.pumpAndSettle();
      await tester.scrollAndTap(find.text('Stage 80'));
      await tester.pumpAndSettle();

      final clipped = tester.clippedTexts(within: find.byType(PlanDetailsPage));
      await tester.disposeApp();
      expect(clipped, isEmpty);
    });
  });
}
