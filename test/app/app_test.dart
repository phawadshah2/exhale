import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
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
        widget.key == const Key('today-count') &&
        widget.textSpan?.toPlainText() == value,
  );

  Future<void> logAndSkipTrigger(WidgetTester tester) async {
    await tester.scrollAndTap(find.text('Log a smoke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
  }

  testWidgets('first launch goes from splash to setup to home', (tester) async {
    await tester.pumpAppPastSplash();
    expect(find.text('Craft your gradual quitting plan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Fawad');
    await tester.scrollAndTap(find.byTooltip('Increase daily amount'));
    await tester.tap(find.text('Start my plan'));
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, Fawad'), findsOneWidget);
    expect(todayCount('0 / 10'), findsOneWidget);
    expect(find.text('10 left today'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a returning user lands on home and can log and undo', (
    tester,
  ) async {
    await sl<SavePlan>()(
      PlanDraft(startDay: LogicalDay(2026, 10, 16), startLimit: 2),
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
    await sl<SavePlan>()(
      PlanDraft(startDay: LogicalDay(2026, 10, 16), startLimit: 9),
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
}
