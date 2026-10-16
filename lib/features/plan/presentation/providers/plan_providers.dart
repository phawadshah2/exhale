import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => sl<PlanRepository>(),
);

final savePlanProvider = Provider<SavePlan>((ref) => sl<SavePlan>());

/// Null until onboarding saves the first plan.
final planHistoryProvider = StreamProvider<PlanHistory?>(
  (ref) => ref.watch(planRepositoryProvider).watchHistory(),
);
