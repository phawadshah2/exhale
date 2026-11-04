import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/usecases/answer_stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/answer_with_new_plan.dart';
import 'package:exhale/features/plan/domain/usecases/keep_original_date.dart';
import 'package:exhale/features/plan/domain/usecases/run_stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => sl<PlanRepository>(),
);

final savePlanProvider = Provider<SavePlan>((ref) => sl<SavePlan>());

final answerStageCheckProvider = Provider<AnswerStageCheck>(
  (ref) => sl<AnswerStageCheck>(),
);

final answerWithNewPlanProvider = Provider<AnswerWithNewPlan>(
  (ref) => sl<AnswerWithNewPlan>(),
);

final keepOriginalDateProvider = Provider<KeepOriginalDate>(
  (ref) => sl<KeepOriginalDate>(),
);

final runStageCheckProvider = Provider<RunStageCheck>(
  (ref) => sl<RunStageCheck>(),
);

/// A habit's plans; null until its first plan is saved.
final StreamProviderFamily<PlanHistory?, int> planHistoryProvider =
    StreamProvider.family<PlanHistory?, int>(
      (ref, habitId) => ref.watch(planRepositoryProvider).watchHistory(habitId),
    );

final stageCheckRepositoryProvider = Provider<StageCheckRepository>(
  (ref) => sl<StageCheckRepository>(),
);

/// A habit's stage checks, newest first.
final StreamProviderFamily<List<StageCheck>, int> stageChecksProvider =
    StreamProvider.family<List<StageCheck>, int>(
      (ref, habitId) =>
          ref.watch(stageCheckRepositoryProvider).watchChecks(habitId),
    );
