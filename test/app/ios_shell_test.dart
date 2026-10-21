import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
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
    await tester.tap(find.text('Skip and save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await tester.longPress(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Log now'), findsOneWidget);
    expect(find.text('Add a missed log'), findsOneWidget);

    await tester.tap(find.text('Add a missed log'));
    await tester.pumpAndSettle();
    expect(find.text('Log now'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close'), findsNothing);

    await tester.disposeApp();
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

    await tester.tap(find.text('Skip and save'));
    await tester.pumpAndSettle();
    await tester.disposeApp();
  });
}
