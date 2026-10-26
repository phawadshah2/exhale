import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => sl<PlanRepository>(),
);

final savePlanProvider = Provider<SavePlan>((ref) => sl<SavePlan>());

/// A habit's plans; null until its first plan is saved.
final StreamProviderFamily<PlanHistory?, int> planHistoryProvider =
    StreamProvider.family<PlanHistory?, int>(
      (ref, habitId) => ref.watch(planRepositoryProvider).watchHistory(habitId),
    );
