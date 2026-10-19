import 'dart:ui';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/pages/habit_picker_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15))));
  tearDown(InjectionContainer.reset);

  Future<void> continueToPlan(WidgetTester tester) async {
    await tester.scrollAndTap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('a preset habit changes the plan wording', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Alcohol'));
    await tester.pump();
    await continueToPlan(tester);

    expect(find.byType(SetupPage), findsOneWidget);
    expect(find.text('Drinks on a normal day'), findsOneWidget);
    expect(find.text('Price per bottle'), findsOneWidget);
    expect(find.text('per bottle'), findsOneWidget);
    expect(find.textContaining('alcohol-free from'), findsOneWidget);
    expect(find.textContaining('drinks avoided'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a habit without packs is priced per unit', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Caffeine'));
    await tester.pump();
    await continueToPlan(tester);

    expect(find.text('Price per cup'), findsOneWidget);
    expect(find.textContaining('per pack'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('custom needs a name and unit before continuing', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupPage), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Habit'),
      'Energy drinks',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'One log is a…'),
      'Can',
    );
    await tester.pump();
    await continueToPlan(tester);

    expect(find.text('Cans on a normal day'), findsOneWidget);
    expect(find.text('Price per can'), findsOneWidget);
    expect(find.textContaining('You reach zero on'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('back returns to the habit step and keeps the choice', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Sugar'));
    await tester.pump();
    await continueToPlan(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitPickerPage), findsOneWidget);
    expect(find.byType(SetupPage), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Sugar'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.disposeApp();
  });
}
