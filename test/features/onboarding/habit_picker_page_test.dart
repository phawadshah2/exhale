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

  testWidgets('leads with vaping, picked by default, in three rows', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    const names = [
      'Vaping',
      'Smoking',
      'Nicotine pouches',
      'Alcohol',
      'Caffeine',
      'Energy drinks',
      'Junk food',
      'Social media',
      'Custom',
    ];
    final icons = [
      for (final name in names)
        tester.getCenter(
          find
              .descendant(
                of: find.bySemanticsLabel(name),
                matching: find.byType(Icon),
              )
              .first,
        ),
    ];
    // The selected tile's thicker border shifts it by half a pixel.
    bool sameRow(Offset a, Offset b) => (a.dy - b.dy).abs() < 4;
    final rows = <Offset>[];
    for (final icon in icons) {
      if (!rows.any((r) => sameRow(r, icon))) rows.add(icon);
    }
    expect(rows, hasLength(3));
    // Reading order: left to right, then top to bottom.
    for (var i = 1; i < icons.length; i++) {
      final prev = icons[i - 1];
      final next = icons[i];
      expect(
        sameRow(prev, next) ? next.dx > prev.dx : next.dy > prev.dy,
        isTrue,
        reason: names[i],
      );
    }
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Vaping'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await continueToPlan(tester);
    expect(find.byType(SetupPage), findsOneWidget);
    expect(find.text('Sessions on a normal day'), findsOneWidget);
    expect(find.text('Price per pod'), findsOneWidget);

    await tester.disposeApp();
  });

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

  testWidgets('social media has no cost card', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Social media'));
    await tester.pump();
    await continueToPlan(tester);

    expect(find.text('What it costs'), findsNothing);
    expect(find.textContaining('sessions avoided'), findsOneWidget);
    expect(find.textContaining('saved'), findsNothing);

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

    await tester.tap(find.text('Junk food'));
    await tester.pump();
    await continueToPlan(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitPickerPage), findsOneWidget);
    expect(find.byType(SetupPage), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Junk food'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.disposeApp();
  });
}
