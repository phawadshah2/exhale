import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/pages/change_habit_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/plan/presentation/pages/plan_details_page.dart';
import 'package:exhale/features/plan/presentation/widgets/price_card.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 11, 19);

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 11, 19, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> openSettings(
    WidgetTester tester, {
    int? priceCents,
    double width = 390,
    double height = 1600,
  }) async {
    await seedHabit(
      PlanDraft(
        startDay: today,
        startLimit: 8,
        quitDay: LogicalDay(2027, 1, 12),
      ),
      habit: Habit.vaping,
      priceCents: priceCents,
    );
    await tester.pumpAppPastSplash(width: width, height: height);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets("Edit plan shows today's limit", (tester) async {
    await openSettings(tester);
    expect(find.text('Edit plan'), findsOneWidget);
    expect(find.text('8 today'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a price reads per container', (tester) async {
    await openSettings(tester, priceCents: 1200);
    expect(find.text(r'$12 a pod'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('no price reads Not set', (tester) async {
    await openSettings(tester);
    expect(
      find.descendant(
        of: find.widgetWithText(SettingsRow, 'Price'),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );
    await tester.disposeApp();
  });

  testWidgets('Price opens Edit plan at the price card', (tester) async {
    await openSettings(tester, height: 844);
    await tester.scrollAndTap(find.text('Price'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditPlanPage>(find.byType(EditPlanPage)).focusPrice,
      isTrue,
    );
    expect(find.byType(PriceCard).hitTestable(), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Price reaches the price card at 200% on a small phone', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openSettings(tester, width: 375, height: 667);
    // Home overflows at this size on its own; only Edit plan is checked here.
    tester.takeException();
    await tester.scrollAndTap(find.text('Price'));
    await tester.pumpAndSettle();

    final card = find.byType(PriceCard);
    expect(card, findsOneWidget);
    final top = tester.getTopLeft(card).dy;
    final error = tester.takeException();
    await tester.disposeApp();
    expect(error, isNull);
    expect(top, inInclusiveRange(0, 667 / 2));
  });

  testWidgets('Change habit opens change habit', (tester) async {
    await openSettings(tester);
    await tester.scrollAndTap(find.text('Change habit'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeHabitPage), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the tile opens plan details', (tester) async {
    await openSettings(tester);
    expect(find.text('Vaping plan'), findsOneWidget);
    expect(find.text('54 days to go'), findsOneWidget);

    await tester.scrollAndTap(find.text('Vaping plan'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailsPage), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('rows are at least 44 tall', (tester) async {
    await openSettings(tester);
    for (final row in tester.widgetList(find.byType(SettingsRow))) {
      expect(
        tester.getSize(find.byWidget(row)).height,
        greaterThanOrEqualTo(44),
      );
    }
    await tester.disposeApp();
  });
}
