import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> toHabitStep(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
  }

  testWidgets('Make a plan opens the habit step', (tester) async {
    await toHabitStep(tester);

    expect(find.text('2/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.habitTitle), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the back chevron returns to Welcome', (tester) async {
    await toHabitStep(tester);

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(find.text('1/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.welcomeTitle), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('a right swipe returns to Welcome', (tester) async {
    await toHabitStep(tester);

    await tester.fling(
      find.text(OnboardingCopy.habitTitle),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('1/6'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a left swipe does not move forward', (tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();

    await tester.fling(
      find.text(OnboardingCopy.welcomeTitle),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('1/6'), findsOneWidget);

    await tester.disposeApp();
  });
}
