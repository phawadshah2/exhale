import 'package:exhale/core/widgets/status_bar_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double top = 44}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(top: top)),
            child: Scaffold(
              body: StatusBarGlass(
                child: ListView(
                  children: [
                    for (var i = 0; i < 30; i++)
                      SizedBox(height: 100, child: Text('row $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  double opacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  testWidgets('is off at the top and on once the page scrolls', (tester) async {
    await pump(tester);
    expect(opacity(tester), 0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);

    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(opacity(tester), 0);
  });

  testWidgets('covers exactly the status bar and takes no touches', (
    tester,
  ) async {
    await pump(tester);
    final strip = find.ancestor(
      of: find.byType(AnimatedOpacity),
      matching: find.byType(Positioned),
    );
    expect(tester.getSize(strip.first).height, 44);
    expect(find.byType(IgnorePointer), findsWidgets);
  });

  testWidgets('draws nothing without a status bar', (tester) async {
    await pump(tester, top: 0);
    expect(find.byType(AnimatedOpacity), findsNothing);
  });
}
