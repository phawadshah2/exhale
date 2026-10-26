import 'package:exhale/app/app.dart';
import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fixed_clock.dart';
import 'test_database.dart';

/// A returning user: [habit] tracked with [plan]. Returns the habit's id.
Future<int> seedHabit(
  PlanDraft plan, {
  Habit habit = Habit.smoking,
  String? reason,
  int? priceCents,
}) async {
  final added = await sl<AddHabit>()(
    HabitDraft(habit: habit, reason: reason, priceCents: priceCents),
  ) as Success<TrackedHabit>;
  await sl<SavePlan>()((habitId: added.value.id, draft: plan));
  return added.value.id;
}

/// Registers real dependencies on an in-memory database.
Future<void> setUpTestDependencies(FixedClock clock) =>
    InjectionContainer.setupDependencies(
      database: createTestDatabase(),
      clock: clock,
    );

void mockPackageInfo() => PackageInfo.setMockInitialValues(
  appName: 'Exhale',
  packageName: 'com.phawadshah.exhale',
  version: '0.1.0',
  buildNumber: '1',
  buildSignature: '',
);

extension PumpApp on WidgetTester {
  /// Launches the app and waits past the splash screen.
  /// [height] is in logical pixels; tall views avoid lazy list disposal.
  Future<void> pumpAppPastSplash({double height = 844}) async {
    view
      ..physicalSize = Size(1170, height * 3)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    mockPackageInfo();
    await pumpWidget(
      ProviderScope(
        overrides: await startupOverrides(),
        child: const ExhaleApp(),
      ),
    );
    await pump(SplashPage.introDuration + SplashPage.holdDuration);
    await pump(const Duration(milliseconds: 100));
    await pumpAndSettle();
  }

  /// Launches a first-run app and moves past the habit step to the plan.
  Future<void> pumpToPlanStep({double height = 844}) async {
    await pumpAppPastSplash(height: height);
    await tap(find.text('Smoking'));
    await pump();
    await tap(find.text('Continue'));
    await pumpAndSettle();
  }

  /// Advances [duration] in 50 ms frames so chained animations play out.
  Future<void> pumpInSteps(Duration duration) async {
    const step = Duration(milliseconds: 50);
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
      await pump(step);
    }
  }

  /// Scrolls [finder] into view, then taps it.
  Future<void> scrollAndTap(Finder finder) async {
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
    await pump();
  }

  /// Unmounts the app so stream subscriptions and timers are released.
  Future<void> disposeApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(Duration.zero);
  }
}
