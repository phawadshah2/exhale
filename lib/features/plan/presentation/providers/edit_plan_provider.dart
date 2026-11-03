import 'dart:math';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
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
  weeks8('8 wks'),
  weeks16('16 wks');

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
    required this.currentLimit,
    required this.currentQuitDay,
    required this.openingLimit,
    required this.openingQuitDay,
    required this.startLimit,
    required this.quitDay,
    required this.unitsPerContainer,
    required this.storedPriceCents,
    required this.storedUnits,
    required this.rulerSpanDays,
    this.quitPreset = EditQuitPreset.keepCurrent,
    this.priceText = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final LogicalDay today;

  /// Today's limit under the plan in force.
  final int currentLimit;

  /// The quit date of the plan in force, offered as "Keep current".
  final LogicalDay currentQuitDay;

  /// The limit and date the form opened with.
  final int openingLimit;
  final LogicalDay openingQuitDay;
  final int startLimit;
  final LogicalDay quitDay;

  /// Null once the user picks a date on the wheel or the ruler.
  final EditQuitPreset? quitPreset;
  final String priceText;
  final int unitsPerContainer;

  /// What is stored now, moved on as soon as a save writes the price.
  final int? storedPriceCents;
  final int storedUnits;

  /// Days the ruler spans from today. Only a chip or the wheel changes it, so
  /// it never moves under a finger.
  final int rulerSpanDays;
  final bool isSubmitting;
  final String? errorMessage;

  PlanDraft get draft =>
      PlanDraft(startDay: today, startLimit: startLimit, quitDay: quitDay);

  /// Past the quit date the form opens on a new plan, which a press starts
  /// unless the price is the only thing changed.
  bool get planChanged => canKeepCurrent
      ? startLimit != currentLimit || quitDay != currentQuitDay
      : !priceChanged ||
            startLimit != openingLimit ||
            quitDay != openingQuitDay;

  /// True for an invalid price too, so pressing save can show its error.
  bool get priceChanged =>
      hasInvalidPrice ||
      priceCents != storedPriceCents ||
      unitsPerContainer != storedUnits;

  bool get canSave => planChanged ? preview != null : priceChanged;

  /// A plan that reached its quit date cannot be kept as it is.
  bool get canKeepCurrent => currentQuitDay.isAfter(today);

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
    int? Function()? storedPriceCents,
    int? storedUnits,
    int? rulerSpanDays,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => EditPlanState(
    today: today,
    currentLimit: currentLimit,
    currentQuitDay: currentQuitDay,
    openingLimit: openingLimit,
    openingQuitDay: openingQuitDay,
    startLimit: startLimit ?? this.startLimit,
    quitDay: quitDay ?? this.quitDay,
    quitPreset: quitPreset != null ? quitPreset() : this.quitPreset,
    priceText: priceText ?? this.priceText,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    storedPriceCents: storedPriceCents != null
        ? storedPriceCents()
        : this.storedPriceCents,
    storedUnits: storedUnits ?? this.storedUnits,
    rulerSpanDays: rulerSpanDays ?? this.rulerSpanDays,
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
    final quitDay = preset.quitDayFor(
      today: today,
      startLimit: startLimit,
      currentQuitDay: plan.quitDay,
    );
    return EditPlanState(
      today: today,
      currentLimit: plan.limitOn(today),
      currentQuitDay: plan.quitDay,
      openingLimit: startLimit,
      openingQuitDay: quitDay,
      startLimit: startLimit,
      quitDay: quitDay,
      quitPreset: preset,
      unitsPerContainer: habit.unitsPerContainer,
      priceText: cents == null ? '' : (cents / 100).toStringAsFixed(2),
      storedPriceCents: cents,
      storedUnits: habit.unitsPerContainer,
      rulerSpanDays: _rulerSpan(today, quitDay),
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

  void selectQuitPreset(EditQuitPreset preset) {
    final quitDay = _quitDayFor(preset, state.startLimit);
    state = state.copyWith(
      quitPreset: () => preset,
      quitDay: quitDay,
      rulerSpanDays: _rulerSpan(state.today, quitDay),
      errorMessage: () => null,
    );
  }

  /// A date picked on the wheel; any day after today is allowed.
  void setQuitDay(LogicalDay day) {
    final quitDay = _notBeforeEarliest(day);
    state = state.copyWith(
      quitDay: quitDay,
      quitPreset: () => null,
      rulerSpanDays: _rulerSpan(state.today, quitDay),
      errorMessage: () => null,
    );
  }

  /// A date dragged on the ruler; the ruler's span stays as it is.
  void setQuitDayFromRuler(LogicalDay day) => state = state.copyWith(
    quitDay: _notBeforeEarliest(day),
    quitPreset: () => null,
    errorMessage: () => null,
  );

  void setPriceText(String text) =>
      state = state.copyWith(priceText: text, errorMessage: () => null);

  void setUnitsPerContainer(int value) => state = state.copyWith(
    unitsPerContainer: value.clamp(1, HabitValidation.maxUnitsPerContainer),
  );

  /// Saves the price if it changed, then starts a new plan today if the plan
  /// changed. Returns true when everything that changed is stored.
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
    if (!state.canSave) return false;
    final form = state;
    state = form.copyWith(isSubmitting: true, errorMessage: () => null);

    if (form.priceChanged) {
      final priceCents = habit.habit.tracksCost ? form.priceCents : null;
      final priced = await ref.read(setHabitPriceProvider)((
        habitId: habitId,
        day: form.today,
        priceCents: priceCents,
        unitsPerContainer: form.unitsPerContainer,
      ));
      if (!ref.mounted) return false;
      if (priced case FailureResult(:final failure)) {
        return _fail(failureMessage(failure));
      }
      state = state.copyWith(
        storedPriceCents: () => priceCents,
        storedUnits: form.unitsPerContainer,
      );
    }

    if (form.planChanged) {
      final saved = await ref.read(savePlanProvider)((
        habitId: habitId,
        draft: form.draft,
      ));
      if (!ref.mounted) return false;
      if (saved case FailureResult(:final failure)) {
        return _fail(failureMessage(failure));
      }
    }

    state = state.copyWith(isSubmitting: false);
    return true;
  }

  bool _fail(String message) {
    state = state.copyWith(isSubmitting: false, errorMessage: () => message);
    return false;
  }

  LogicalDay _notBeforeEarliest(LogicalDay day) {
    final earliest = earliestQuitDay;
    return day.isBefore(earliest) ? earliest : day;
  }

  /// 17 weeks, or 4 weeks past [quitDay] if that is later.
  int _rulerSpan(LogicalDay today, LogicalDay quitDay) =>
      max(119, quitDay.daysSince(today) + 28);

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
