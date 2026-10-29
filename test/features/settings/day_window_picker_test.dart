import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/settings/presentation/widgets/day_window_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = DayWindow(
    wakeMinute: DayWindow.defaultWake,
    bedMinute: DayWindow.defaultBed,
  );

  Future<List<DayWindow>> pumpPicker(
    WidgetTester tester, {
    DayWindow initial = defaults,
  }) async {
    final reported = <DayWindow>[];
    var window = initial;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DayWindowPicker(
              window: window,
              onChanged: (value) {
                reported.add(value);
                setState(() => window = value);
              },
            ),
          ),
        ),
      ),
    );
    return reported;
  }

  void spinTo(WidgetTester tester, int hour, int minute) {
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2000, 1, 1, hour, minute));
  }

  testWidgets('the defaults read 7:30 AM, 11:30 PM and 16 h awake', (
    tester,
  ) async {
    await pumpPicker(tester);

    expect(find.text(OnboardingCopy.wakeUp), findsOneWidget);
    expect(find.text(OnboardingCopy.bedtime), findsOneWidget);
    expect(find.text('7:30 AM'), findsOneWidget);
    expect(find.text('11:30 PM'), findsOneWidget);
    expect(find.text('16 h awake'), findsOneWidget);
  });

  testWidgets('a bedtime after midnight is a longer day, not a negative one', (
    tester,
  ) async {
    final reported = await pumpPicker(tester);

    await tester.tap(find.text(OnboardingCopy.bedtime));
    await tester.pumpAndSettle();
    spinTo(tester, 1, 0);
    await tester.pumpAndSettle();

    expect(reported, [const DayWindow(wakeMinute: 450, bedMinute: 60)]);
    expect(find.text('1:00 AM'), findsOneWidget);
    expect(find.text('17 h 30 min awake'), findsOneWidget);
  });

  testWidgets('the wake tile edits the wake time', (tester) async {
    final reported = await pumpPicker(tester);

    spinTo(tester, 6, 15);
    await tester.pumpAndSettle();

    expect(reported, [const DayWindow(wakeMinute: 375, bedMinute: 1410)]);
    expect(find.text('6:15 AM'), findsOneWidget);
    expect(find.text('17 h 15 min awake'), findsOneWidget);
  });

  testWidgets(
    'a window under 4 h is not reported and the tile keeps its time',
    (tester) async {
      final reported = await pumpPicker(
        tester,
        initial: const DayWindow(wakeMinute: 450, bedMinute: 120),
      );
      expect(find.text('18 h 30 min awake'), findsOneWidget);

      spinTo(tester, 23, 0);
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(find.text('7:30 AM'), findsOneWidget);
      expect(find.text('11:00 PM'), findsNothing);
      expect(find.text('18 h 30 min awake'), findsOneWidget);
    },
  );
}
