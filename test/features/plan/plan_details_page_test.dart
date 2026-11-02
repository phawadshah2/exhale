import 'dart:async';

import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/presentation/pages/plan_details_page.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
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

    testWidgets("the plan card's Edit pill still opens Edit plan", (
      tester,
    ) async {
      await seedK();
      await tester.pumpAppPastSplash(height: 2400);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit plan'), findsOneWidget);
      expect(find.text(title), findsNothing);
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
  });

  group('rings', () {
    StageRingPainter painterOf(WidgetTester tester, Finder ring) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(of: ring, matching: find.byType(CustomPaint)),
                )
                .painter!
            as StageRingPainter;

    testWidgets('fill is used over allowed, capped, and warns when over', (
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
      expect(over.color, context.exhale.warning.solid);

      final under = painterOf(tester, find.byType(StageRing).at(1));
      expect(under.fill, closeTo(21 / 77, 0.001));
      expect(under.color, context.colors.primaryContainer);
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

    testWidgets("a stage's over figures use the warning colour", (
      tester,
    ) async {
      await seedK();
      await logOn(start, times: 90);
      await openDetails(tester);

      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();

      final warning = tester
          .element(find.text('90 of 84 used'))
          .exhale
          .warning
          .foreground;
      expect(
        tester.widget<Text>(find.text('90 of 84 used')).style?.color,
        warning,
      );
      expect(tester.widget<Text>(find.text('1 of 7')).style?.color, warning);
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

  group('at 3x text on an SE width', () {
    setUpAll(loadAppFonts);
    setUp(() {
      binding.platformDispatcher.textScaleFactorTestValue = 3;
    });
    tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);

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
