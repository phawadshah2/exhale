import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 29, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> openSettings(WidgetTester tester) async {
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
    );
    await tester.pumpAppPastSplash();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('Your day shows Not set, then the saved times', (tester) async {
    await openSettings(tester);
    expect(find.text('Your day'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);

    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsNothing);
    expect(find.text('7:30 AM – 11:30 PM'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Your day opens on the stored times', (tester) async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 360, bedMinute: () => 60),
    );

    await openSettings(tester);
    expect(find.text('6:00 AM – 1:00 AM'), findsOneWidget);

    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();

    expect(find.text('6:00 AM'), findsOneWidget);
    expect(find.text('1:00 AM'), findsOneWidget);
    await tester.disposeApp();
  });
}
