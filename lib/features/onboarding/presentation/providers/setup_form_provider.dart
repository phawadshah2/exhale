import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/validation/settings_validation.dart';
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
    this.quitPreset = QuitPreset.suggested,
    this.name = '',
    this.startLimit = defaultStartLimit,
    this.packPriceText = '',
    this.cigarettesPerPack = AppSettings.defaultCigarettesPerPack,
    this.isSubmitting = false,
    this.errorMessage,
  });

  factory SetupFormState.initial(LogicalDay today) => SetupFormState(
    startDay: today,
    quitDay: QuitPreset.suggested.quitDayFor(today, defaultStartLimit),
  );

  static const int defaultStartLimit = 9;

  final LogicalDay startDay;
  final LogicalDay quitDay;

  /// Null once the user picks a date on the wheel.
  final QuitPreset? quitPreset;
  final String name;
  final int startLimit;
  final String packPriceText;
  final int cigarettesPerPack;
  final bool isSubmitting;
  final String? errorMessage;

  PlanDraft get draft =>
      PlanDraft(startDay: startDay, startLimit: startLimit, quitDay: quitDay);

  /// More than one fewer per day: allowed, with a warning.
  bool get isSteep => PlanValidation.isSteep(draft);

  int? get packPriceCents => AppFormat.parseCents(packPriceText);

  bool get hasInvalidPackPrice =>
      packPriceText.trim().isNotEmpty &&
      (packPriceCents == null ||
          packPriceCents! > SettingsValidation.maxPackPriceCents);

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
    String? name,
    int? startLimit,
    String? packPriceText,
    int? cigarettesPerPack,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => SetupFormState(
    startDay: startDay ?? this.startDay,
    quitDay: quitDay ?? this.quitDay,
    quitPreset: quitPreset != null ? quitPreset() : this.quitPreset,
    name: name ?? this.name,
    startLimit: startLimit ?? this.startLimit,
    packPriceText: packPriceText ?? this.packPriceText,
    cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}

final NotifierProvider<SetupFormController, SetupFormState> setupFormProvider =
    NotifierProvider.autoDispose(SetupFormController.new);

class SetupFormController extends Notifier<SetupFormState> {
  @override
  SetupFormState build() => SetupFormState.initial(ref.read(todayProvider));

  /// Earliest and latest quit days allowed for the current start day.
  (LogicalDay, LogicalDay) get quitDayRange => (
    state.startDay.addDays(PlanValidation.minPlanDays),
    state.startDay.addDays(PlanValidation.maxPlanDays),
  );

  void setName(String name) => state = state.copyWith(name: name);

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

  /// A date picked on the wheel; clamped into the allowed range.
  void setQuitDay(LogicalDay day) {
    final (earliest, latest) = quitDayRange;
    final quitDay = day.isBefore(earliest)
        ? earliest
        : day.isAfter(latest)
        ? latest
        : day;
    state = state.copyWith(
      quitDay: quitDay,
      quitPreset: () => null,
      errorMessage: () => null,
    );
  }

  void setPackPriceText(String text) =>
      state = state.copyWith(packPriceText: text, errorMessage: () => null);

  void setCigarettesPerPack(int value) => state = state.copyWith(
    cigarettesPerPack: value.clamp(1, SettingsValidation.maxCigarettesPerPack),
  );

  /// Saves settings and the plan. Returns true when both are stored.
  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    if (state.hasInvalidPackPrice) {
      state = state.copyWith(
        errorMessage: () => 'Enter a valid pack price, or leave it empty.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    final form = state;

    final settingsResult = await ref
        .read(settingsActionsProvider)
        .update(
          (current) => current.copyWith(
            userName: () => form.name,
            packPriceCents: () => form.packPriceCents,
            cigarettesPerPack: form.cigarettesPerPack,
          ),
        );
    if (!ref.mounted) return false;
    if (settingsResult case FailureResult(:final failure)) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => failureMessage(failure),
      );
      return false;
    }

    final planResult = await ref.read(savePlanProvider)(form.draft);
    if (!ref.mounted) return false;
    if (planResult case FailureResult(:final failure)) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => failureMessage(failure),
      );
      return false;
    }

    state = state.copyWith(isSubmitting: false);
    return true;
  }

  /// Keeps the quit date tied to the chosen preset, or inside the allowed
  /// range for a hand-picked date.
  SetupFormState _withQuitFollowingPreset(SetupFormState next) {
    final preset = next.quitPreset;
    if (preset != null) {
      return next.copyWith(
        quitDay: preset.quitDayFor(next.startDay, next.startLimit),
      );
    }
    final earliest = next.startDay.addDays(PlanValidation.minPlanDays);
    final latest = next.startDay.addDays(PlanValidation.maxPlanDays);
    if (next.quitDay.isBefore(earliest)) {
      return next.copyWith(quitDay: earliest);
    }
    if (next.quitDay.isAfter(latest)) return next.copyWith(quitDay: latest);
    return next;
  }
}
