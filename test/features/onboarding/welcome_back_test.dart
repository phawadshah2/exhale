import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/welcome_back_page.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/presentation/pages/paywall_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 11, 13);
  final saved = today.addDays(-5);

  setUp(
    () => setUpTestDependencies(
      FixedClock(DateTime(2026, 11, 13, 9)),
      store: FakeStoreRepository(),
    ),
  );

  tearDown(InjectionContainer.reset);

  /// Smoking at 6 a day on Steady (8 weeks), saved five days ago.
  Future<int> seedUnpaid({String? name}) async {
    final id = await seedHabit(
      PlanDraft(startDay: saved, startLimit: 6, quitDay: saved.addDays(56)),
    );
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(current.value.copyWith(userName: () => name));
    return id;
  }

  Future<List<ReductionPlan>> plans(int habitId) async =>
      ((await sl<PlanRepository>().getHistory(
        habitId,
      )) as Success<PlanHistory?>).value!.plans;

  Finder go(String? pace, LogicalDay quitDay) => find.descendant(
    of: planButton(),
    matching: find.text(
      OnboardingCopy.dealGo(pace, AppFormat.monthDay(quitDay)),
    ),
  );

  testWidgets('shows the saved plan from today and saves it on the button', (
    tester,
  ) async {
    final habitId = await seedUnpaid(name: 'Sam');
    reduceMotion(tester);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byKey(WelcomeBackPage.pageKey), findsOneWidget);
    expect(find.text('Welcome back, Sam.'), findsOneWidget);
    expect(find.text("Your plan's still here."), findsOneWidget);
    expect(find.text(OnboardingCopy.dealHeadline), findsNothing);
    expect(go('Steady', today.addDays(56)), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsNothing);

    await tester.tap(planButton().hitTestable());
    await tester.pumpAndSettle();

    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
    final stored = await tester.runAsync(() => plans(habitId));
    expect(stored, [
      ReductionPlan(startDay: today, startLimit: 6, quitDay: today.addDays(56)),
    ]);

    await tester.disposeApp();
  });

  testWidgets('with no name the eyebrow says Welcome back.', (tester) async {
    await seedUnpaid();
    reduceMotion(tester);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Welcome back.'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('another pace replaces the plan and keeps one habit', (
    tester,
  ) async {
    final habitId = await seedUnpaid(name: 'Sam');
    reduceMotion(tester);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Brisk'));
    await tester.pumpAndSettle();
    await tester.tap(planButton().hitTestable());
    await tester.pumpAndSettle();

    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
    await tester.runAsync(() async {
      expect(await plans(habitId), [
        ReductionPlan(
          startDay: today,
          startLimit: 6,
          quitDay: today.addDays(28),
        ),
      ]);
      final habits =
          await sl<HabitRepository>().getActive()
              as Success<List<TrackedHabit>>;
      expect(habits.value, hasLength(1));
    });

    await tester.disposeApp();
  });
}
