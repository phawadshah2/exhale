import 'package:exhale/features/plan/domain/entities/plan_draft.dart';

abstract final class PlanValidation {
  static const int minStartLimit = 1;
  static const int maxStartLimit = 80;

  /// The quit date must be after the start; there is no upper limit.
  static const int minPlanDays = 1;

  /// First problem with [draft], or null when it can become a plan.
  static String? validate(PlanDraft draft) {
    if (draft.startLimit < minStartLimit || draft.startLimit > maxStartLimit) {
      return 'Daily amount must be between $minStartLimit and $maxStartLimit.';
    }
    if (draft.totalDays < minPlanDays) {
      return 'Pick a quit date after your start date.';
    }
    return null;
  }

  /// True when the limit must fall by more than one a day: allowed, but
  /// worth a gentle warning.
  static bool isSteep(PlanDraft draft) =>
      draft.totalDays > 0 && draft.startLimit > draft.totalDays;
}
