import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  /// Walks the first-run flow, running [check] on every step.
  Future<void> walk(
    WidgetTester tester,
    Future<void> Function() check,
    double height,
  ) async {
    Future<void> next() async {
      final button = find.text(OnboardingCopy.continueButton).hitTestable();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tester.pumpAppPastSplash(height: height);
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await check();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Habit.smoking.name));
    await tester.pumpAndSettle();
    await check(); // Habit.
    await next();
    await check(); // Daily amount.
    await next();
    await check(); // Cost.
    await next();
    await check(); // Your day.
    await next();
    await check(); // The deal.
    await tester.disposeApp();
  }

  testWidgets('every step meets the 44 pt tap target', (tester) async {
    final handle = tester.ensureSemantics();
    await walk(tester, () async {
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }, 2400);
    handle.dispose();
  });

  testWidgets('every step has no overflow at 3x text', (tester) async {
    binding.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);
    // An overflow on any step fails the test by itself.
    await walk(tester, () async {}, 5000);
  });
}
