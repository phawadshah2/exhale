import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/amount_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/amount_ruler.dart';
import 'package:exhale/features/onboarding/presentation/widgets/dots_grid.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> toSmokingAmount(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Habit.smoking.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingCopy.continueButton).last);
    await tester.pumpAndSettle();
  }

  Finder inStep(Finder matching) =>
      find.descendant(of: find.byType(AmountStep), matching: matching);

  Future<void> tapPlus(WidgetTester tester) async {
    await tester.tap(inStep(find.byIcon(AppIcons.add)));
    await tester.pump();
  }

  Future<void> tapMinus(WidgetTester tester, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(inStep(find.byIcon(AppIcons.remove)));
      await tester.pump();
    }
  }

  Future<void> swapReply(WidgetTester tester) =>
      tester.pumpInSteps(const Duration(milliseconds: 200));

  int startLimit(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(AmountStep)))
          .read(onboardingFormProvider)
          .startLimit;

  testWidgets('smoking starts at 9, respectable', (tester) async {
    await toSmokingAmount(tester);

    expect(find.text('3/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.amountPrompt), findsOneWidget);
    expect(find.text(OnboardingCopy.amountTitle('cigarettes')), findsOneWidget);
    expect(inStep(find.text('9')), findsOneWidget);
    expect(find.text('Respectable. For now.'), findsOneWidget);
    final dots = tester.widget<DotsGrid>(find.byType(DotsGrid));
    expect((dots.count, dots.unit), (9, 1));
    expect(find.textContaining('Each dot is'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('+ and − change the number and the reaction', (tester) async {
    await toSmokingAmount(tester);

    await tapPlus(tester);
    expect(inStep(find.text('10')), findsOneWidget);
    await swapReply(tester);
    expect(
      find.text("That's not a habit. That's a part-time job."),
      findsOneWidget,
    );

    await tapMinus(tester, times: 6);
    expect(inStep(find.text('4')), findsOneWidget);
    await swapReply(tester);
    expect(find.text('Practically a hobby.'), findsOneWidget);
    expect(tester.widget<DotsGrid>(find.byType(DotsGrid)).count, 4);

    await tapMinus(tester, times: 3);
    expect(startLimit(tester), 1);
    await tapMinus(tester);
    expect(startLimit(tester), 1);
    expect(inStep(find.text('1')), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the ruler follows the finger', (tester) async {
    await toSmokingAmount(tester);

    await tester.drag(find.byType(AmountRuler), const Offset(-60, 0));
    await tester.pumpAndSettle();
    final raised = startLimit(tester);
    expect(raised, greaterThan(9));
    expect(inStep(find.text('$raised')), findsOneWidget);

    await tester.drag(find.byType(AmountRuler), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(startLimit(tester), lessThan(9));
    expect(find.text('3/6'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('at the maximum there are 12 dots and + stops', (tester) async {
    await toSmokingAmount(tester);
    ProviderScope.containerOf(tester.element(find.byType(AmountStep)))
        .read(onboardingFormProvider.notifier)
        .setStartLimit(PlanValidation.maxStartLimit);
    await tester.pump();
    await swapReply(tester);

    final dots = tester.widget<DotsGrid>(find.byType(DotsGrid));
    expect((dots.count, dots.unit), (12, 7));
    expect(find.text('Each dot is 7 cigarettes'), findsOneWidget);
    expect(find.text("That's a full-time job with overtime."), findsOneWidget);

    await tapPlus(tester);
    expect(startLimit(tester), 80);
    expect(inStep(find.text('80')), findsOneWidget);

    await tester.drag(find.byType(AmountRuler), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(startLimit(tester), 80);

    await tester.disposeApp();
  });
}
