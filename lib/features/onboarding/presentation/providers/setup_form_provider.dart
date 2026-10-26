import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick quit-date choices. While one is selected the quit date follows the
/// start date (and, for [suggested], the daily amount).
enum QuitPreset {
  weeks4('4 weeks'),
  weeks8('8 weeks'),
  months3('3 months'),
  suggested('Suggested');

  QuitPreset(this.label);

  final String label;

  LogicalDay quitDayFor(LogicalDay startDay, int startLimit) => switch (this) {
    QuitPreset.weeks4 => startDay.addDays(28),
    QuitPreset.weeks8 => startDay.addDays(56),
    QuitPreset.months3 => startDay.addDays(91),
    QuitPreset.suggested => ReductionPlan.suggestedQuitDay(
      startDay,
      startLimit,
    ),
  };
}

@immutable
class SetupFormState {
  const SetupFormState({
    required this.startDay,
    required this.quitDay,
    required this.startLimit,
    required this.unitsPerContainer,
    this.quitPreset = QuitPreset.suggested,
    this.habitKind = defaultHabit,
    this.customName = '',
    this.customUnit = '',
    this.reason = '',
    this.name = '',
    this.priceText = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Starts on [defaultHabit] (the app leads with vaping) and its amounts.
  factory SetupFormState.initial(LogicalDay today) {
    final habit = Habit.presets.firstWhere((h) => h.kind == defaultHabit);
    return SetupFormState(
      startDay: today,
      startLimit: habit.defaultDailyAmount,
      unitsPerContainer: habit.defaultUnitsPerContainer,
      quitDay: QuitPreset.suggested.quitDayFor(today, habit.defaultDailyAmount),
    );
  }

  static const HabitKind defaultHabit = HabitKind.vaping;

  final LogicalDay startDay;
  final LogicalDay quitDay;

  /// Null once the user picks a date on the wheel.
  final QuitPreset? quitPreset;

  final HabitKind habitKind;
  final String customName;
  final String customUnit;
  final String reason;
  final String name;
  final int startLimit;
  final String priceText;
  final int unitsPerContainer;
  final bool isSubmitting;
  final String? errorMessage;

  Habit get habit => habitKind == HabitKind.custom
      ? Habit.custom(name: customName, unit: customUnit)
      : Habit.presets.firstWhere((h) => h.kind == habitKind);

  /// A custom habit needs a name and a unit before moving on.
  bool get canContinue =>
      habitKind != HabitKind.custom ||
      (customName.trim().isNotEmpty && customUnit.trim().isNotEmpty);

  /// Price of one unit, from the container price when the habit has one.
  double? get unitPriceCents {
    final price = priceCents;
    if (price == null) return null;
    return habit.hasContainer ? price / unitsPerContainer : price.toDouble();
  }

  PlanDraft get draft =>
      PlanDraft(startDay: startDay, startLimit: startLimit, quitDay: quitDay);

  /// More than one fewer per day: allowed, with a warning.
  bool get isSteep => PlanValidation.isSteep(draft);

  int? get priceCents => AppFormat.parseCents(priceText);

  bool get hasInvalidPrice =>
      priceText.trim().isNotEmpty &&
      (priceCents == null || priceCents! > HabitValidation.maxPriceCents);

  /// The plan this form would create, or null while it is invalid.
  ReductionPlan? get preview => PlanValidation.validate(draft) == null
      ? ReductionPlan(
          startDay: startDay,
          startLimit: startLimit,
          quitDay: quitDay,
        )
      : null;

  SetupFormState copyWith({
    LogicalDay? startDay,
    LogicalDay? quitDay,
    QuitPreset? Function()? quitPreset,
    HabitKind? habitKind,
    String? customName,
    String? customUnit,
    String? reason,
    String? name,
    int? startLimit,
    String? priceText,
    int? unitsPerContainer,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => SetupFormState(
    startDay: startDay ?? this.startDay,
    quitDay: quitDay ?? this.quitDay,
    quitPreset: quitPreset != null ? quitPreset() : this.quitPreset,
    habitKind: habitKind ?? this.habitKind,
    customName: customName ?? this.customName,
    customUnit: customUnit ?? this.customUnit,
    reason: reason ?? this.reason,
    name: name ?? this.name,
    startLimit: startLimit ?? this.startLimit,
    priceText: priceText ?? this.priceText,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}

final NotifierProvider<SetupFormController, SetupFormState> setupFormProvider =
    NotifierProvider.autoDispose(SetupFormController.new);

class SetupFormController extends Notifier<SetupFormState> {
  @override
  SetupFormState build() => SetupFormState.initial(ref.read(todayProvider));

  /// Earliest quit day for the current start day; there is no latest.
  LogicalDay get earliestQuitDay =>
      state.startDay.addDays(PlanValidation.minPlanDays);

  void setName(String name) => state = state.copyWith(name: name);

  /// Switches habit and resets the amounts to that habit's defaults.
  void selectHabit(HabitKind kind) {
    if (kind == state.habitKind) return;
    final habit = state.copyWith(habitKind: kind).habit;
    state = _withQuitFollowingPreset(
      state.copyWith(
        habitKind: kind,
        startLimit: habit.defaultDailyAmount,
        unitsPerContainer: habit.defaultUnitsPerContainer,
        errorMessage: () => null,
      ),
    );
  }

  void setCustomName(String text) => state = state.copyWith(customName: text);

  void setCustomUnit(String text) => state = state.copyWith(customUnit: text);

  void setReason(String text) => state = state.copyWith(reason: text);

  void setStartLimit(int value) {
    final startLimit = value.clamp(
      PlanValidation.minStartLimit,
      PlanValidation.maxStartLimit,
    );
    state = _withQuitFollowingPreset(
      state.copyWith(startLimit: startLimit, errorMessage: () => null),
    );
  }

  void setStartDay(LogicalDay day) => state = _withQuitFollowingPreset(
    state.copyWith(startDay: day, errorMessage: () => null),
  );

  void selectQuitPreset(QuitPreset preset) => state = state.copyWith(
    quitPreset: () => preset,
    quitDay: preset.quitDayFor(state.startDay, state.startLimit),
    errorMessage: () => null,
  );

  /// A date picked on the wheel; any day after the start is allowed.
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

  /// Saves the name, then the habit with its plan. Returns true when all
  /// are stored.
  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    if (state.hasInvalidPrice) {
      state = state.copyWith(
        errorMessage: () => 'Enter a valid price, or leave it empty.',
      );
      return false;
    }
    final form = state;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    // A second submit (setup reached again) must not add a second habit.
    final existing = await ref.read(habitRepositoryProvider).getActive();
    if (!ref.mounted) return false;
    if (existing case Success(value: [_, ...])) {
      state = state.copyWith(isSubmitting: false);
      return true;
    }

    final settingsResult = await ref
        .read(settingsActionsProvider)
        .update((current) => current.copyWith(userName: () => form.name));
    if (!ref.mounted) return false;
    if (settingsResult case FailureResult(:final failure)) {
      return _fail(failureMessage(failure));
    }

    final result = await ref.read(startTrackingProvider)((
      habit: HabitDraft(
        habit: form.habit,
        reason: form.reason,
        priceCents: form.habit.tracksCost ? form.priceCents : null,
        unitsPerContainer: form.unitsPerContainer,
      ),
      plan: form.draft,
    ));
    if (!ref.mounted) return false;
    if (result case FailureResult(:final failure)) {
      return _fail(failureMessage(failure));
    }

    state = state.copyWith(isSubmitting: false);
    return true;
  }

  bool _fail(String message) {
    state = state.copyWith(isSubmitting: false, errorMessage: () => message);
    return false;
  }

  /// Keeps the quit date tied to the chosen preset, or after the start for
  /// a hand-picked date.
  SetupFormState _withQuitFollowingPreset(SetupFormState next) {
    final preset = next.quitPreset;
    if (preset != null) {
      return next.copyWith(
        quitDay: preset.quitDayFor(next.startDay, next.startLimit),
      );
    }
    final earliest = next.startDay.addDays(PlanValidation.minPlanDays);
    return next.quitDay.isBefore(earliest)
        ? next.copyWith(quitDay: earliest)
        : next;
  }
}
