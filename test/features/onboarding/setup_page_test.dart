import 'package:exhale/core/di/injection_container.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026; no plan yet, so the app opens on setup.
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15))));
  tearDown(InjectionContainer.reset);

  testWidgets('suggests a quit date and updates it from presets', (
    tester,
  ) async {
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('18 Dec 2026'), findsWidgets);
    expect(find.text('in 9 weeks'), findsOneWidget);
    expect(
      find.text('Your limit drops by 1 about every 7 days.'),
      findsOneWidget,
    );

    await tester.tap(find.text('4 weeks'));
    await tester.pumpAndSettle();
    expect(find.text('13 Nov 2026'), findsWidgets);
    expect(find.text('in 4 weeks'), findsOneWidget);
    expect(
      find.text('Your limit drops by 1 about every 3 days.'),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('warns when the pace is more than one a day', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    for (var i = 0; i < 25; i++) {
      await tester.tap(find.byTooltip('Increase daily amount'));
      await tester.pump();
    }
    await tester.tap(find.text('4 weeks'));
    await tester.pumpAndSettle();

    expect(find.textContaining('more than one fewer a day'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the start button stays put when the keyboard opens', (
    tester,
  ) async {
    await tester.pumpAppPastSplash();
    final before = tester.getRect(find.text('Start my plan'));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text('Start my plan')), before);

    await tester.disposeApp();
  });
}
