import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  late FixedClock clock;

  setUp(() async {
    clock = FixedClock(DateTime(2026, 10, 16, 15, 42));
    await setUpTestDependencies(clock);
  });

  tearDown(InjectionContainer.reset);

  Finder todayCount(String value) => find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.key == const Key('day-count') &&
        widget.textSpan?.toPlainText() == value,
  );

  Future<void> logAndSkipTrigger(WidgetTester tester) async {
    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save without trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
  }

  testWidgets('first launch goes from splash through onboarding to home', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.text('1/6'), findsOneWidget);

    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
    for (final label in ['2/6', '3/6', '4/6', '5/6']) {
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(OnboardingCopy.continueButton).hitTestable());
      await tester.pumpAndSettle();
    }
    expect(find.text('6/6'), findsOneWidget);

    await tester.tap(find.text(OnboardingCopy.dealButton).hitTestable());
    await tester.pumpAndSettle();

    final limit = Habit.vaping.defaultDailyAmount;
    expect(todayCount('0 / $limit'), findsOneWidget);
    expect(find.text('$limit left today'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a returning user lands on home and can log and undo', (
    tester,
  ) async {
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 16),
        startLimit: 2,
        quitDay: LogicalDay(2026, 10, 16).addDays(14),
      ),
    );

    await tester.pumpAppPastSplash(height: 2400);
    expect(todayCount('0 / 2'), findsOneWidget);

    await logAndSkipTrigger(tester);
    expect(todayCount('1 / 2'), findsOneWidget);
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await logAndSkipTrigger(tester);
    expect(find.text('Limit reached'), findsOneWidget);

    await logAndSkipTrigger(tester);
    expect(todayCount('3 / 2'), findsOneWidget);
    expect(find.text('1 over limit'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(todayCount('2 / 2'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('theme choice in settings is saved and applied', (tester) async {
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 16),
        startLimit: 9,
        quitDay: LogicalDay(2026, 10, 16).addDays(63),
      ),
    );
    await tester.pumpAppPastSplash();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsPage));
    expect(Theme.of(context).brightness, Brightness.light);
    final stored = await sl<SettingsRepository>().get();
    expect(
      (stored as Success<AppSettings>).value.themePreference,
      ThemePreference.light,
    );

    await tester.disposeApp();
  });

  testWidgets('the trigger prompt can be turned off in settings', (
    tester,
  ) async {
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 16),
        startLimit: 9,
        quitDay: LogicalDay(2026, 10, 16).addDays(63),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask for a trigger'));
    await tester.pumpAndSettle();

    final stored = await sl<SettingsRepository>().get();
    expect((stored as Success<AppSettings>).value.askForTrigger, isFalse);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(find.text('What triggered this one?'), findsNothing);
    expect(todayCount('1 / 9'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a new accent re-tints the app and is saved', (tester) async {
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 16),
        startLimit: 9,
        quitDay: LogicalDay(2026, 10, 16).addDays(63),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ocean accent'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsPage));
    final theme = Theme.of(context);
    expect(
      theme.colorScheme.primaryContainer,
      AppTheme.of(
        theme.brightness,
        accent: AppPalette.ocean,
      ).colorScheme.primaryContainer,
    );
    final stored = await tester.runAsync(() => sl<SettingsRepository>().get());
    expect((stored! as Success<AppSettings>).value.accentIndex, 1);

    await tester.disposeApp();
  });
}
