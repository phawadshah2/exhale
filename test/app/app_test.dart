import 'package:exhale/app/app.dart';
import 'package:exhale/features/design_system/presentation/design_system_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(DesignSystemPage))).brightness;

  testWidgets('tapping a theme segment switches the whole app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExhaleApp()));
    expect(brightnessOf(tester), Brightness.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);
  });
}
