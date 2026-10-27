import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Quick quit-date choices on Edit plan. While one is selected the quit date
/// follows the daily limit (for [suggested]) or today.
enum EditQuitPreset {
  keepCurrent('Keep current'),
  suggested('Suggested'),
  weeks8('8 weeks'),
  weeks16('16 weeks');

  EditQuitPreset(this.label);

  final String label;

  LogicalDay quitDayFor({
    required LogicalDay today,
    required int startLimit,
    required LogicalDay currentQuitDay,
  }) => switch (this) {
    EditQuitPreset.keepCurrent => currentQuitDay,
    EditQuitPreset.suggested => ReductionPlan.suggestedQuitDay(
      today,
      startLimit,
    ),
    EditQuitPreset.weeks8 => today.addDays(56),
    EditQuitPreset.weeks16 => today.addDays(112),
  };
}

@immutable
class EditPlanState {
  const EditPlanState({
    required this.today,
    required this.currentQuitDay,
    required this.startLimit,
    required this.quitDay,
    required this.unitsPerContainer,
    this.quitPreset = EditQuitPreset.keepCurrent,
    this.priceText = '',
    this.reason = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final LogicalDay today;

  /// The quit date of the plan in force, offered as "Keep current".
  final LogicalDay currentQuitDay;
  final int startLimit;
  final LogicalDay quitDay;

  /// Null once the user picks a date on the wheel.
  final EditQuitPreset? quitPreset;
  final String priceText;
  final int unitsPerContainer;
  final String reason;
  final bool isSubmitting;
  final String? errorMessage;

  PlanDraft get draft =>
      PlanDraft(startDay: today, startLimit: startLimit, quitDay: quitDay);

  bool get isSteep => PlanValidation.isSteep(draft);

  int? get priceCents => AppFormat.parseCents(priceText);

  bool get hasInvalidPrice =>
      priceText.trim().isNotEmpty &&
      (priceCents == null || priceCents! > HabitValidation.maxPriceCents);

  /// The plan this form would start today, or null while it is invalid.
  ReductionPlan? get preview => PlanValidation.validate(draft) == null
      ? ReductionPlan(startDay: today, startLimit: startLimit, quitDay: quitDay)
      : null;

  EditPlanState copyWith({
    int? startLimit,
    LogicalDay? quitDay,
    EditQuitPreset? Function()? quitPreset,
    String? priceText,
    int? unitsPerContainer,
    String? reason,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => EditPlanState(
    today: today,
    currentQuitDay: currentQuitDay,
    startLimit: startLimit ?? this.startLimit,
    quitDay: quitDay ?? this.quitDay,
    quitPreset: quitPreset != null ? quitPreset() : this.quitPreset,
    priceText: priceText ?? this.priceText,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    reason: reason ?? this.reason,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}

/// Edit plan form for one habit. The page shows it only once the habit and
/// its plan history have loaded.
final NotifierProviderFamily<EditPlanController, EditPlanState, int>
editPlanProvider = NotifierProvider.autoDispose
    .family<EditPlanController, EditPlanState, int>(EditPlanController.new);

class EditPlanController extends Notifier<EditPlanState> {
  EditPlanController(this.habitId);

  final int habitId;

  @override
  EditPlanState build() {
    final today = ref.read(todayProvider);
    final habit = ref.read(habitProvider(habitId))!;
    final plan = ref.read(planHistoryProvider(habitId)).value!.current;
    final cents = habit.priceCents;
    // A plan that reached its quit date cannot be kept as it is.
    final canKeep = plan.quitDay.isAfter(today);
    final startLimit = plan
        .limitOn(today)
        .clamp(PlanValidation.minStartLimit, PlanValidation.maxStartLimit);
    final preset = canKeep
        ? EditQuitPreset.keepCurrent
        : EditQuitPreset.suggested;
    return EditPlanState(
      today: today,
      currentQuitDay: plan.quitDay,
      startLimit: startLimit,
      quitDay: preset.quitDayFor(
        today: today,
        startLimit: startLimit,
        currentQuitDay: plan.quitDay,
      ),
      quitPreset: preset,
      unitsPerContainer: habit.unitsPerContainer,
      priceText: cents == null ? '' : (cents / 100).toStringAsFixed(2),
      reason: habit.reason ?? '',
    );
  }

  /// Earliest quit day: tomorrow, as the new plan starts today.
  LogicalDay get earliestQuitDay =>
      state.today.addDays(PlanValidation.minPlanDays);

  void setDailyLimit(int value) {
    final startLimit = value.clamp(
      PlanValidation.minStartLimit,
      PlanValidation.maxStartLimit,
    );
    state = _followPreset(
      state.copyWith(startLimit: startLimit, errorMessage: () => null),
    );
  }

  void selectQuitPreset(EditQuitPreset preset) => state = state.copyWith(
    quitPreset: () => preset,
    quitDay: _quitDayFor(preset, state.startLimit),
    errorMessage: () => null,
  );

  /// A date picked on the wheel; any day after today is allowed.
  void setQuitDay(LogicalDay day) {
    final earliest = earliestQuitDay;
    state = state.copyWith(
      quitDay: day.isBefore(earliest) ? earliest : day,
      quitPreset: () => null,
      errorMessage: () => null,
    );
  }

  void setPriceText(String text) =>
      state = state.copyWith(priceText: text, errorMessage: () => null);

  void setUnitsPerContainer(int value) => state = state.copyWith(
    unitsPerContainer: value.clamp(1, HabitValidation.maxUnitsPerContainer),
  );

  void setReason(String text) => state = state.copyWith(reason: text);

  /// Saves the habit's price and reason, then starts the new plan today.
  /// Returns true when both are stored.
  Future<bool> save() async {
    if (state.isSubmitting) return false;
    final habit = ref.read(habitProvider(habitId));
    if (habit == null) return false;
    if (state.hasInvalidPrice) {
      state = state.copyWith(
        errorMessage: () => 'Enter a valid price, or leave it empty.',
      );
      return false;
    }
    final form = state;
    state = form.copyWith(isSubmitting: true, errorMessage: () => null);

    final updated = await ref.read(updateHabitProvider)(_updatedHabit(habit));
    if (!ref.mounted) return false;
    if (updated case FailureResult(:final failure)) {
      return _fail(failureMessage(failure));
    }

    final saved = await ref.read(savePlanProvider)((
      habitId: habitId,
      draft: form.draft,
    ));
    if (!ref.mounted) return false;
    if (saved case FailureResult(:final failure)) {
      return _fail(failureMessage(failure));
    }

    state = state.copyWith(isSubmitting: false);
    return true;
  }

  TrackedHabit _updatedHabit(TrackedHabit habit) => habit.copyWith(
    priceCents: () => habit.habit.tracksCost ? state.priceCents : null,
    unitsPerContainer: state.unitsPerContainer,
    reason: () => state.reason,
  );

  bool _fail(String message) {
    state = state.copyWith(isSubmitting: false, errorMessage: () => message);
    return false;
  }

  LogicalDay _quitDayFor(EditQuitPreset preset, int startLimit) =>
      preset.quitDayFor(
        today: state.today,
        startLimit: startLimit,
        currentQuitDay: state.currentQuitDay,
      );

  EditPlanState _followPreset(EditPlanState next) {
    final preset = next.quitPreset;
    if (preset != null) {
      return next.copyWith(quitDay: _quitDayFor(preset, next.startLimit));
    }
    return next;
  }
}
