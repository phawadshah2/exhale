import 'package:exhale/features/plan/domain/entities/plan_draft.dart';

abstract final class PlanValidation {
  static const int minStartLimit = 1;
  static const int maxStartLimit = 80;
  static const int minStepDays = 1;
  static const int maxStepDays = 30;

  /// First problem with [draft], or null when it can become a plan.
  static String? validate(PlanDraft draft) {
    if (draft.startLimit < minStartLimit || draft.startLimit > maxStartLimit) {
      return 'Daily amount must be between $minStartLimit and $maxStartLimit.';
    }
    if (draft.stepDays < minStepDays || draft.stepDays > maxStepDays) {
      return 'Reduction pace must be between $minStepDays and $maxStepDays '
          'days.';
    }
    if (draft.targetLimit < 0) {
      return 'Target cannot be negative.';
    }
    if (draft.targetLimit >= draft.startLimit) {
      return 'Target must be lower than your daily amount.';
    }
    return null;
  }
}
