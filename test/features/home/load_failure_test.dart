import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);

  setUp(
    () => setUpTestDependencies(FixedClock(DateTime(2026, 10, 29, 15, 42))),
  );
  tearDown(InjectionContainer.reset);

  Future<void> seed() => seedHabit(
    PlanDraft(
      startDay: today.addDays(-3),
      startLimit: 9,
      quitDay: today.addDays(60),
    ),
  );

  const failure = "Couldn't load your habit.";

  testWidgets('Home says so when the habits fail, and can retry', (
    tester,
  ) async {
    await seed();
    var attempts = 0;
    await tester.pumpAppPastSplash(
      overrides: [
        activeHabitsProvider.overrideWith((ref) {
          attempts++;
          return attempts == 1
              ? Stream.error(StateError('storage'))
              : sl<HabitRepository>().watchActive();
        }),
      ],
    );

    expect(find.text(failure), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(failure), findsNothing);
    expect(find.text("Today's Consumption"), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Home says so when the plan fails, and can retry', (
    tester,
  ) async {
    await seed();
    var attempts = 0;
    await tester.pumpAppPastSplash(
      overrides: [
        planHistoryProvider.overrideWith((ref, id) {
          attempts++;
          return attempts == 1
              ? Stream.error(StateError('storage'))
              : const Stream.empty();
        }),
      ],
    );

    expect(find.text(failure), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text(failure), findsNothing);
    await tester.disposeApp();
  });

  testWidgets("Home says so when today's logs fail", (tester) async {
    await seed();
    await tester.pumpAppPastSplash(
      overrides: [
        logsForDayProvider.overrideWith(
          (ref, key) => Stream.error(StateError('storage')),
        ),
      ],
    );

    expect(find.text(failure), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Edit plan says so and offers a way back', (tester) async {
    await seed();
    await tester.pumpAppPastSplash(
      overrides: [
        planHistoryProvider.overrideWith(
          (ref, id) => Stream.error(StateError('storage')),
        ),
      ],
    );
    final context = tester.element(find.byType(HomePage));
    unawaited(GoRouter.of(context).push(AppRoutes.editPlanFor(1)));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text("Couldn't load your plan."), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a failed read at launch keeps a returning user out of '
      'onboarding, and can retry', (tester) async {
    await seed();
    final real = sl<HabitRepository>();
    sl
      ..unregister<HabitRepository>()
      ..registerSingleton<HabitRepository>(_FailFirstReadRepository(real));

    await tester.pumpAppPastSplash();

    expect(find.text("Couldn't open your data."), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    await tester.disposeApp();
  });
}

/// The real repository, except the first [getActive] fails as storage would.
class _FailFirstReadRepository implements HabitRepository {
  _FailFirstReadRepository(this._real);

  final HabitRepository _real;
  bool _failed = false;

  @override
  Future<Result<List<TrackedHabit>>> getActive() {
    if (_failed) return _real.getActive();
    _failed = true;
    return guardStorage<List<TrackedHabit>>(
      'FailFirstReadRepository',
      () async => throw const FormatException('disk error'),
    );
  }

  @override
  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  }) => _real.add(draft, createdAt: createdAt);

  @override
  Stream<List<TrackedHabit>> watchActive() => _real.watchActive();

  @override
  Future<Result<void>> update(TrackedHabit habit) => _real.update(habit);

  @override
  Future<Result<void>> archive(int id, {required DateTime at}) =>
      _real.archive(id, at: at);

  @override
  Stream<List<PricePoint>> watchPrices(int habitId) =>
      _real.watchPrices(habitId);

  @override
  Future<Result<void>> setPrice(
    int habitId, {
    required LogicalDay day,
    required int? priceCents,
    required int unitsPerContainer,
  }) => _real.setPrice(
    habitId,
    day: day,
    priceCents: priceCents,
    unitsPerContainer: unitsPerContainer,
  );
}
