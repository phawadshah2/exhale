import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

/// 44 pt everywhere except a Week chart day: seven full-height columns share
/// the card's width, so each is about 41 pt wide and 186 pt tall.
class _AppTapTargets extends MinimumTapTargetGuideline {
  const _AppTapTargets()
    : super(
        size: const Size(44, 44),
        link: 'https://developer.apple.com/design/human-interface-guidelines',
      );

  static final _chartDay = RegExp(r'^\w+day, \w+ \d+: ');

  @override
  bool shouldSkipNode(SemanticsNode node) =>
      super.shouldSkipNode(node) ||
      _chartDay.hasMatch(node.getSemanticsData().label);
}

void main() {
  final today = LogicalDay(2026, 10, 29);
  final clock = FixedClock(DateTime(2026, 10, 29, 15, 42));

  setUp(() => setUpTestDependencies(clock));
  tearDown(InjectionContainer.reset);

  // Tall enough that nothing sits under the floating bar, which the contrast
  // check would read as the text's background. Logs have no trigger because it
  // would read a trigger row's bar the same way; test/core/theme and
  // trigger_ui_test cover those colours.
  const height = 3000.0;

  Future<void> seed({
    required ThemePreference theme,
    required int accent,
  }) async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(
        themePreference: theme,
        accentIndex: accent,
        wakeMinute: () => 450,
        bedMinute: () => 1410,
      ),
    );
    final habitId = await seedHabit(
      PlanDraft(
        startDay: today.addDays(-3),
        startLimit: 9,
        quitDay: today.addDays(60),
      ),
    );
    for (final hour in [8, 10, 12]) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: habitId,
          loggedAt: DateTime(2026, 10, 29, hour),
          note: 'After lunch',
        ),
      );
    }
  }

  // Disposes either way: a failure that leaves the app up hangs the run.
  Future<void> expectGuidelines(
    WidgetTester tester,
    SemanticsHandle handle,
  ) async {
    try {
      await expectLater(tester, meetsGuideline(const _AppTapTargets()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      handle.dispose();
      await tester.disposeApp();
    }
  }

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    for (final accent in [0, 1, 2]) {
      group('${theme.name}, accent $accent', () {
        testWidgets('Home', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          await expectGuidelines(tester, handle);
        });

        testWidgets('Logs', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          final context = tester.element(find.byType(Scaffold).first);
          unawaited(
            GoRouter.of(context).push(
              LogsQuery(habitId: 1, from: today, to: today).toUri().toString(),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('The evidence.'), findsOneWidget);
          await expectGuidelines(tester, handle);
        });

        testWidgets('Settings', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          expect(find.text('Appearance'), findsOneWidget);
          await expectGuidelines(tester, handle);
        });

        testWidgets('Edit plan', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          final context = tester.element(find.byType(Scaffold).first);
          unawaited(GoRouter.of(context).push(AppRoutes.editPlanFor(1)));
          await tester.pumpAndSettle();
          expect(find.text('Change habit'), findsOneWidget);
          await expectGuidelines(tester, handle);
        });

        testWidgets('Plan details', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          final context = tester.element(find.byType(Scaffold).first);
          unawaited(GoRouter.of(context).push(AppRoutes.planDetailsFor(1)));
          await tester.pumpAndSettle();
          expect(find.text('The whole plan'), findsOneWidget);
          await expectGuidelines(tester, handle);
        });

        testWidgets('the trigger sheet', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          await tester.tap(find.byTooltip('Log'));
          await tester.pumpAndSettle();
          expect(find.text('What triggered this one?'), findsOneWidget);
          await expectGuidelines(tester, handle);
        });

        testWidgets('the Edit log sheet', (tester) async {
          final handle = tester.ensureSemantics();
          await seed(theme: theme, accent: accent);
          await tester.pumpAppPastSplash(height: height);
          await tester.scrollAndTap(find.text('12:00 PM'));
          await tester.pumpAndSettle();
          expect(find.text('Edit log'), findsWidgets);
          await expectGuidelines(tester, handle);
        });
      });
    }
  }
}
