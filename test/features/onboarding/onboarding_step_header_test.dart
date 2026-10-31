import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a one-line title lines up with the lead', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: OnboardingStepHeader(
            prompt: 'Hi',
            title: 'Short title',
            lead: 'A lead that sits under the title',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Short title')).dx,
      tester.getTopLeft(find.text('A lead that sits under the title')).dx,
    );
  });
}
