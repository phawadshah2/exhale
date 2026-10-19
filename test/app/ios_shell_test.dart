import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    await sl<SavePlan>()(
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

  testWidgets('glass effects can be turned off and are saved', (tester) async {
    await tester.pumpAppPastSplash();
    expect(glassOn(tester), isTrue);
    expect(find.byType(BackdropFilter), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Glass effects'));
    await tester.pumpAndSettle();

    expect(glassOn(tester), isFalse);
    final stored = await tester.runAsync(() => sl<SettingsRepository>().get());
    expect((stored! as Success<AppSettings>).value.glassEffects, isFalse);

    await tester.disposeApp();
  });

  testWidgets('sheets float above the tab bar on the root navigator', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Log a smoke'));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.text('What triggered this smoke?'));
    final tabBar = tester.getRect(find.byTooltip('Home'));
    expect(find.text('What triggered this smoke?'), findsOneWidget);
    // The sheet is a root route, so it is painted over the tab bar area.
    expect(sheet.top, lessThan(tabBar.top));

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.disposeApp();
  });
}
