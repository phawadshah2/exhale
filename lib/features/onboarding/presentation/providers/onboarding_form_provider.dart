import 'dart:math' as math;

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/currency_choices.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingStep { welcome, chat, habit, amount, cost, deal }

/// The habit this form takes the place of; null on a first run. Overridden by
/// a nested scope in `ChangeHabitPage`.
final replacedHabitProvider = Provider<TrackedHabit?>(
  (ref) => null,
  dependencies: const [],
);

/// Quick quit-date choices, in chip order. While one is selected the quit
/// date follows the daily amount (for [suggested]).
enum QuitPreset {
  suggested('Suggested'),
  weeks4('4 weeks'),
  weeks8('8 weeks'),
  months3('3 months');

  QuitPreset(this.label);

  final String label;

  LogicalDay quitDayFor(LogicalDay startDay, int startLimit) => switch (this) {
    QuitPreset.suggested => ReductionPlan.suggestedQuitDay(
      startDay,
      startLimit,
    ),
    QuitPreset.weeks4 => startDay.addDays(28),
    QuitPreset.weeks8 => startDay.addDays(56),
    QuitPreset.months3 => startDay.addDays(91),
  };
}

@immutable
class OnboardingFormState {
  const OnboardingFormState({
    required this.startDay,
    required this.quitDay,
    required this.startLimit,
    required this.unitsPerContainer,
    required this.currency,
    this.replaced,
    this.quitPreset = QuitPreset.suggested,
    this.habitKind = defaultHabit,
    this.customName = '',
    this.customUnit = '',
    this.userName = '',
    this.priceText = '',
    this.wakeMinute = DayWindow.defaultWake,
    this.bedMinute = DayWindow.defaultBed,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Starts today on [defaultHabit] (the app leads with vaping) and its
  /// amounts.
  factory OnboardingFormState.initial(LogicalDay today, String currency) {
    final habit = Habit.presets.firstWhere((h) => h.kind == defaultHabit);
    return OnboardingFormState(
      startDay: today,
      startLimit: habit.defaultDailyAmount,
      unitsPerContainer: habit.defaultUnitsPerContainer,
      quitDay: QuitPreset.suggested.quitDayFor(today, habit.defaultDailyAmount),
      currency: currency,
    );
  }

  /// A habit to replace [replaced]: starts on the first other preset, with the
  /// saved day and currency. Those stay as they are, so the form never edits
  /// them.
  factory OnboardingFormState.changing(
    LogicalDay today,
    AppSettings settings,
    TrackedHabit replaced,
  ) {
    final habit = Habit.presets.firstWhere(
      (h) => h.kind != replaced.habit.kind,
    );
    final window = settings.dayWindow;
    return OnboardingFormState(
      replaced: replaced,
      habitKind: habit.kind,
      startDay: today,
      startLimit: habit.defaultDailyAmount,
      unitsPerContainer: habit.defaultUnitsPerContainer,
      quitDay: QuitPreset.suggested.quitDayFor(today, habit.defaultDailyAmount),
      currency: settings.currencySymbol,
      wakeMinute: window?.wakeMinute ?? DayWindow.defaultWake,
      bedMinute: window?.bedMinute ?? DayWindow.defaultBed,
    );
  }

  static const HabitKind defaultHabit = HabitKind.vaping;

  /// Dots shown before each dot stands for more than one unit.
  static const int maxDots = 12;

  /// The habit this form takes the place of; null on a first run.
  final TrackedHabit? replaced;

  final LogicalDay startDay;
  final LogicalDay quitDay;

  /// Null once the user picks a date on the wheel.
  final QuitPreset? quitPreset;

  final HabitKind habitKind;
  final String customName;
  final String customUnit;

  /// What the user told the chat to call them; empty when they declined.
  final String userName;
  final int startLimit;
  final String priceText;
  final int unitsPerContainer;
  final String currency;
  final int wakeMinute;
  final int bedMinute;
  final bool isSubmitting;
  final String? errorMessage;

  Habit get habit => habitKind == HabitKind.custom
      ? Habit.custom(name: customName, unit: customUnit)
      : Habit.presets.firstWhere((h) => h.kind == habitKind);

  bool get isChangingHabit => replaced != null;

  /// The preset being replaced, which a fresh start on belongs to Edit plan.
  bool isTracked(HabitKind kind) =>
      kind != HabitKind.custom && replaced?.habit.kind == kind;

  /// A first run is the welcome, the chat and the plan. Changing the habit
  /// keeps the habit, amount and cost steps (cost only for habits that track
  /// it) before the plan.
  List<OnboardingStep> get steps => isChangingHabit
      ? [
          OnboardingStep.habit,
          OnboardingStep.amount,
          if (habit.tracksCost) OnboardingStep.cost,
          OnboardingStep.deal,
        ]
      : [OnboardingStep.welcome, OnboardingStep.chat, OnboardingStep.deal];

  int get total => steps.length;

  String stepLabel(OnboardingStep step) => '${steps.indexOf(step) + 1}/$total';

  /// A custom habit needs a name and a unit before moving on.
  bool get canContinue =>
      habitKind != HabitKind.custom ||
      (customName.trim().isNotEmpty && customUnit.trim().isNotEmpty);

  /// Units per dot: 1 up to [maxDots], then enough to keep [maxDots] or
  /// fewer.
  int get dotUnit => startLimit <= maxDots ? 1 : (startLimit / maxDots).ceil();

  int get dotCount => (startLimit / dotUnit).ceil();

  /// The price only counts for a habit that tracks cost.
  int? get priceCents =>
      habit.tracksCost ? AppFormat.parseCents(priceText) : null;

  /// Price of one unit, from the container price when the habit has one.
  double? get unitPriceCents {
    final price = priceCents;
    if (price == null) return null;
    return habit.hasContainer ? price / unitsPerContainer : price.toDouble();
  }

  int? get monthlyCostCents => _costOver(30);

  int? get yearlyCostCents => _costOver(365);

  int? _costOver(int days) {
    final unit = unitPriceCents;
    return unit == null ? null : (unit * startLimit * days).round();
  }

  bool get hasInvalidPrice {
    if (!habit.tracksCost || priceText.trim().isEmpty) return false;
    final cents = AppFormat.parseCents(priceText);
    return cents == null || cents > HabitValidation.maxPriceCents;
  }

  DayWindow get dayWindow =>
      DayWindow(wakeMinute: wakeMinute, bedMinute: bedMinute);

  /// Minutes between uses if today's limit is spread across the waking day.
  int get paceMinutes =>
      math.max(1, (dayWindow.awakeMinutes / startLimit).round());

  PlanDraft get draft =>
      PlanDraft(startDay: startDay, startLimit: startLimit, quitDay: quitDay);

  /// More than one fewer per day: allowed, with a warning.
  bool get isSteep => PlanValidation.isSteep(draft);

  /// The plan this form would create, or null while it is invalid.
  ReductionPlan? get preview => PlanValidation.validate(draft) == null
      ? ReductionPlan(
          startDay: startDay,
          startLimit: startLimit,
          quitDay: quitDay,
        )
      : null;

  int get tomorrowLimit => preview?.limitOn(startDay.addDays(1)) ?? startLimit;

  OnboardingFormState copyWith({
    LogicalDay? quitDay,
    QuitPreset? Function()? quitPreset,
    HabitKind? habitKind,
    String? customName,
    String? customUnit,
    String? userName,
    int? startLimit,
    String? priceText,
    int? unitsPerContainer,
    String? currency,
    int? wakeMinute,
    int? bedMinute,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => OnboardingFormState(
    replaced: replaced,
    startDay: startDay,
    quitDay: quitDay ?? this.quitDay,
    quitPreset: quitPreset != null ? quitPreset() : this.quitPreset,
    habitKind: habitKind ?? this.habitKind,
    customName: customName ?? this.customName,
    customUnit: customUnit ?? this.customUnit,
    userName: userName ?? this.userName,
    startLimit: startLimit ?? this.startLimit,
    priceText: priceText ?? this.priceText,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    currency: currency ?? this.currency,
    wakeMinute: wakeMinute ?? this.wakeMinute,
    bedMinute: bedMinute ?? this.bedMinute,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}

final NotifierProvider<OnboardingFormController, OnboardingFormState>
onboardingFormProvider = NotifierProvider.autoDispose(
  OnboardingFormController.new,
  dependencies: [replacedHabitProvider],
);

class OnboardingFormController extends Notifier<OnboardingFormState> {
  @override
  OnboardingFormState build() => switch (ref.read(replacedHabitProvider)) {
    null => OnboardingFormState.initial(
      ref.read(todayProvider),
      CurrencyChoices.forRegion(ref.read(deviceRegionProvider)),
    ),
    final replaced => OnboardingFormState.changing(
      ref.read(todayProvider),
      ref.read(currentSettingsProvider),
      replaced,
    ),
  };

  /// Earliest quit day; there is no latest.
  LogicalDay get earliestQuitDay =>
      state.startDay.addDays(PlanValidation.minPlanDays);

  /// Switches habit and resets the amounts to that habit's defaults.
  void selectHabit(HabitKind kind) {
    if (kind == state.habitKind || state.isTracked(kind)) return;
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

  void setUserName(String text) => state = state.copyWith(userName: text);

  void setStartLimit(int value) {
    final startLimit = value.clamp(
      PlanValidation.minStartLimit,
      PlanValidation.maxStartLimit,
    );
    state = _withQuitFollowingPreset(
      state.copyWith(startLimit: startLimit, errorMessage: () => null),
    );
  }

  void selectQuitPreset(QuitPreset preset) => state = state.copyWith(
    quitPreset: () => preset,
    quitDay: preset.quitDayFor(state.startDay, state.startLimit),
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

  /// "I'd rather not know".
  void skipPrice() =>
      state = state.copyWith(priceText: '', errorMessage: () => null);

  void setUnitsPerContainer(int value) => state = state.copyWith(
    unitsPerContainer: value.clamp(1, HabitValidation.maxUnitsPerContainer),
  );

  void setCurrency(String symbol) => state = state.copyWith(currency: symbol);

  /// Ignored when the window is shorter than [DayWindow.minAwakeMinutes].
  void setDayWindow({required int wakeMinute, required int bedMinute}) {
    final window = DayWindow(wakeMinute: wakeMinute, bedMinute: bedMinute);
    if (!window.isValid) return;
    state = state.copyWith(wakeMinute: wakeMinute, bedMinute: bedMinute);
  }

  /// Saves the day and currency, then the habit with its plan. Returns true
  /// when all are stored. Changing the habit saves only the new habit and its
  /// plan, in place of the old one.
  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    if (state.hasInvalidPrice) {
      state = state.copyWith(errorMessage: () => OnboardingCopy.invalidPrice);
      return false;
    }
    final form = state;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    final replaced = form.replaced;
    if (replaced == null) {
      // A second submit (onboarding reached again) must not add a second
      // habit.
      final existing = await ref.read(habitRepositoryProvider).getActive();
      if (!ref.mounted) return false;
      if (existing case FailureResult(:final failure)) {
        return _fail(failureMessage(failure));
      }
      if (existing case Success(value: [_, ...])) {
        state = state.copyWith(isSubmitting: false);
        return true;
      }

      final settingsResult = await ref
          .read(settingsActionsProvider)
          .update(
            (current) => current.copyWith(
              wakeMinute: () => form.wakeMinute,
              bedMinute: () => form.bedMinute,
              currencySymbol: form.currency,
              userName: () => form.userName.isEmpty ? null : form.userName,
            ),
          );
      if (!ref.mounted) return false;
      if (settingsResult case FailureResult(:final failure)) {
        return _fail(failureMessage(failure));
      }
    }

    final draft = HabitDraft(
      habit: form.habit,
      priceCents: form.priceCents,
      unitsPerContainer: form.unitsPerContainer,
    );
    final result = replaced == null
        ? await ref.read(startTrackingProvider)((
            habit: draft,
            plan: form.draft,
          ))
        : await ref.read(changeHabitProvider)((
            replacedHabitId: replaced.id,
            habit: draft,
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

  /// Keeps the quit date tied to the chosen preset, or after today for a
  /// hand-picked date.
  OnboardingFormState _withQuitFollowingPreset(OnboardingFormState next) {
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
