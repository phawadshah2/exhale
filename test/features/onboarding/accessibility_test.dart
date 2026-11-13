import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  /// Walks a first run with Reduce Motion on, running [check] on the
  /// welcome, on each chat card as it opens, and on the plan.
  Future<void> walk(
    WidgetTester tester,
    Future<void> Function() check, {
    double height = 2400,
    List<Override> overrides = const [],
  }) async {
    Future<void> tapThenCheck(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await settleChat(tester);
      await check();
    }

    reduceMotion(tester);
    await tester.pumpAppPastSplash(height: height, overrides: overrides);
    await check(); // Welcome.
    await tapThenCheck(find.text(OnboardingCopy.welcomeButton)); // Name.
    await tester.enterText(
      find.widgetWithText(TextField, OnboardingCopy.nameHint),
      'Alex',
    );
    await tapThenCheck(labelled(OnboardingCopy.sendName)); // Habit.
    await tapThenCheck(find.text(Habit.smoking.name)); // Amount.
    await tapThenCheck(find.text(OnboardingCopy.aboutRight)); // Price.
    await tapThenCheck(find.text(OnboardingCopy.other)); // Its field.
    await tester.enterText(
      find.widgetWithText(TextField, OnboardingCopy.priceHint),
      '14.50',
    );
    await tapThenCheck(labelled(OnboardingCopy.sendPrice)); // Per pack.
    await tapThenCheck(find.text(OnboardingCopy.aboutRight)); // Day.
    await tapThenCheck(find.text(OnboardingCopy.thatsMyDay)); // Done.
    await tapThenCheck(find.text(OnboardingCopy.chatSeePlan)); // The plan.
    await tester.disposeApp();
  }

  testWidgets('every screen meets the 44 pt tap target', (tester) async {
    final handle = tester.ensureSemantics();
    await walk(tester, () async {
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
    handle.dispose();
  });

  testWidgets('every screen has no overflow at 200% text', (tester) async {
    binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    final clipped = <String>{};
    // An overflow fails the test by itself. The tagline keeps to one line
    // with an ellipsis by design.
    await walk(tester, () async {
      final taglines = {
        for (final line in tester.widgetList<ChatTagline>(
          find.byType(ChatTagline),
        ))
          line.text,
      };
      clipped.addAll(
        tester.clippedTexts().where((text) => !taglines.contains(text)),
      );
    }, height: 5000);
    expect(clipped, isEmpty);
  });

  testWidgets('dark mode with Reduce Transparency renders every screen', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await walk(
      tester,
      () async => expect(tester.takeException(), isNull),
      overrides: [
        reduceTransparencyProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
  });

  testWidgets(
    'cards are named groups, answers are buttons, the status is read',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOnboardingChat(tester);
      expect(labelled(OnboardingCopy.cardName), findsOneWidget);

      await answerName(tester);
      expect(labelled(OnboardingCopy.cardName), findsNothing);
      expect(labelled(OnboardingCopy.cardHabit), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^You: Alex$'))),
        isSemantics(
          isButton: true,
          hasTapAction: true,
          hint: OnboardingCopy.changeHint,
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Read \d{1,2}:\d{2} [AP]M$')),
        findsOneWidget,
      );

      await tester.disposeApp();
      handle.dispose();
    },
  );
}
