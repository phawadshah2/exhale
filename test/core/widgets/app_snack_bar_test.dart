import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> show(
    WidgetTester tester, {
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSnackBar(
                context,
                message: 'Logged at 3:42 PM',
                actionLabel: onAction == null ? null : 'Undo',
                onAction: onAction,
                duration: duration,
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
  }

  testWidgets('animates in and shows the message', (tester) async {
    await show(tester);
    await tester.pump(const Duration(milliseconds: 100));
    final midway = tester.getTopLeft(find.text('Logged at 3:42 PM')).dy;

    await tester.pump(const Duration(milliseconds: 500));
    final settled = tester.getTopLeft(find.text('Logged at 3:42 PM')).dy;

    expect(settled, lessThan(midway));
  });

  testWidgets('closes on its own after the duration', (tester) async {
    await show(tester, onAction: () {});
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Logged at 3:42 PM'), findsNothing);
  });

  testWidgets('the action runs and closes the snackbar', (tester) async {
    var undone = false;
    await show(tester, onAction: () => undone = true);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, isTrue);
    expect(find.text('Logged at 3:42 PM'), findsNothing);
  });

  testWidgets('stays longer for screen-reader users when it has an action', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await show(tester, onAction: () {});
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('a new snackbar replaces the visible one instead of queueing', (
    tester,
  ) async {
    await show(tester, onAction: () {});
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('show'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });
}
