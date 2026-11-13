import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/local/database/drift_transaction_runner.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/features/habit/habit_injection.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:exhale/features/paywall/paywall_injection.dart';
import 'package:exhale/features/plan/plan_injection.dart';
import 'package:exhale/features/settings/settings_injection.dart';
import 'package:exhale/features/tracking/tracking_injection.dart';
import 'package:get_it/get_it.dart';

/// Service locator for data sources, repositories, use cases and services.
/// Riverpod providers read their dependencies from here.
final GetIt sl = GetIt.instance;

abstract final class InjectionContainer {
  /// [database], [clock] and [store] are overridable for tests.
  static Future<void> setupDependencies({
    AppDatabase? database,
    Clock clock = const Clock(),
    StoreRepository? store,
  }) async {
    sl
      ..registerLazySingleton<AppDatabase>(
        () => database ?? AppDatabase(),
        dispose: (db) => db.close(),
      )
      ..registerSingleton<Clock>(clock)
      ..registerLazySingleton<TransactionRunner>(
        () => DriftTransactionRunner(sl<AppDatabase>()),
      );
    initHabitDependencies(sl);
    initPlanDependencies(sl);
    initTrackingDependencies(sl);
    initSettingsDependencies(sl);
    initPaywallDependencies(sl, store);
  }

  static Future<void> reset() => sl.reset();
}
