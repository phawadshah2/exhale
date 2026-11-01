import 'dart:async';
import 'dart:ui';

import 'package:exhale/app/app.dart';
import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/home/presentation/widgets/history_card.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final today = LogicalDay(2026, 10, 29);
  final clock = FixedClock(DateTime(2026, 10, 29, 15, 42));

  setUp(() => setUpTestDependencies(clock));
  tearDown(InjectionContainer.reset);

  Future<int> seed({int logs = 3}) async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
    );
    final habitId = await seedHabit(
      PlanDraft(
        startDay: today.addDays(-3),
        startLimit: 9,
        quitDay: today.addDays(60),
      ),
    );
    for (var i = 0; i < logs; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: habitId,
          loggedAt: DateTime(2026, 10, 29, 8 + i),
          trigger: Trigger.avoidingTasks,
          note: 'Between meetings, again',
        ),
      );
    }
    return habitId;
  }

  group('at 3x text', () {
    setUp(() {
      binding.platformDispatcher.textScaleFactorTestValue = 3;
    });
    tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);

    testWidgets('Home has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      final error = tester.takeException();
      await tester.disposeApp();
      expect(error, isNull);
    });

    testWidgets('Logs has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(
        GoRouter.of(context).push(
          LogsQuery(habitId: 1, from: today, to: today).toUri().toString(),
        ),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      await tester.disposeApp();
      expect(error, isNull);
    });

    testWidgets('Settings has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.disposeApp();
    });

    testWidgets('Edit plan has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(GoRouter.of(context).push(AppRoutes.editPlanFor(1)));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      await tester.disposeApp();
      expect(error, isNull);
    });

    testWidgets('the Edit log sheet has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      await tester.scrollAndTap(find.text('10:00 AM'));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      await tester.disposeApp();
      expect(error, isNull);
    });

    testWidgets('the trigger sheet has no overflow', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 6000);
      await tester.tap(find.byTooltip('Log'));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      await tester.disposeApp();
      expect(error, isNull);
    });
  });

  group('VoiceOver', () {
    testWidgets('+ offers tap and long press', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);

      final node = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Log',
        ),
      );
      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('the tabs can be activated', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);

      final node = tester.getSemantics(find.byTooltip('Settings'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('a day on the Week chart can be activated', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Thursday, Oct 29: 3 of \d+$')),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('a day on the Month rings can be activated', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryCard),
          matching: find.text('Month'),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Thursday, Oct 29: 3 of \d+$')),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('the All chart describes itself', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryCard),
          matching: find.text('All'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'All time chart: 3 logged since Oct 26, plan ends Dec 28',
        ),
        findsOneWidget,
      );
      handle.dispose();
      await tester.disposeApp();
    });

    testWidgets('a trigger row reads as a sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await seed();
      await tester.pumpAppPastSplash(height: 2400);

      final node = tester.getSemantics(
        find.bySemanticsLabel(
          'Avoiding tasks: 3 logs, 100 percent. Open logs.',
        ),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
      await tester.disposeApp();
    });
  });

  testWidgets('Reduce Transparency: no glass on Home or in a sheet', (
    tester,
  ) async {
    await seed();
    tester.view
      ..physicalSize = const Size(1170, 2400 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    mockPackageInfo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await startupOverrides(),
          reduceTransparencyProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const ExhaleApp(),
      ),
    );
    await tester.pump(SplashPage.introDuration + SplashPage.holdDuration);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.disposeApp();
  });

  group('Reduce Motion', () {
    setUp(() {
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
    });
    tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

    testWidgets('SmoothSwitcher swaps at once', (tester) async {
      Widget at(String text) => MaterialApp(
        home: SmoothSwitcher(
          resize: true,
          child: Text(text, key: ValueKey(text)),
        ),
      );
      await tester.pumpWidget(at('one'));
      await tester.pumpWidget(at('two'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('one'), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('PressScale does not move', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PressScale(child: Text('press'))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('press')),
      );
      await tester.pump();
      await tester.pump();
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('the ring and charts land at once on Home', (tester) async {
      await seed();
      await tester.pumpAppPastSplash(height: 2400);
      // Every implicit animation is scaled down, so a short pump settles it.
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.disposeApp();
    });
  });
}
