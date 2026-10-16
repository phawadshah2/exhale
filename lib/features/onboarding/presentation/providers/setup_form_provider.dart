import 'dart:math' as math;

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

@immutable
class SetupFormState {
  const SetupFormState({
    required this.startDay,
    this.name = '',
    this.startLimit = 9,
    this.stepDays = ReductionPlan.defaultStepDays,
    this.quitCompletely = true,
    this.customTarget = 1,
    this.packPriceText = '',
    this.cigarettesPerPack = AppSettings.defaultCigarettesPerPack,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final LogicalDay startDay;
  final String name;
  final int startLimit;
  final int stepDays;
  final bool quitCompletely;
  final int customTarget;
  final String packPriceText;
  final int cigarettesPerPack;
  final bool isSubmitting;
  final String? errorMessage;

  int get targetLimit => quitCompletely ? 0 : customTarget;

  PlanDraft get draft => PlanDraft(
    startDay: startDay,
    startLimit: startLimit,
    stepDays: stepDays,
    targetLimit: targetLimit,
  );

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
          stepDays: stepDays,
          targetLimit: targetLimit,
        )
      : null;

  SetupFormState copyWith({
    LogicalDay? startDay,
    String? name,
    int? startLimit,
    int? stepDays,
    bool? quitCompletely,
    int? customTarget,
    String? packPriceText,
    int? cigarettesPerPack,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) => SetupFormState(
    startDay: startDay ?? this.startDay,
    name: name ?? this.name,
    startLimit: startLimit ?? this.startLimit,
    stepDays: stepDays ?? this.stepDays,
    quitCompletely: quitCompletely ?? this.quitCompletely,
    customTarget: customTarget ?? this.customTarget,
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
  SetupFormState build() => SetupFormState(startDay: ref.read(todayProvider));

  void setName(String name) => state = state.copyWith(name: name);

  void setStartLimit(int value) {
    final startLimit = value.clamp(
      PlanValidation.minStartLimit,
      PlanValidation.maxStartLimit,
    );
    state = state.copyWith(
      startLimit: startLimit,
      customTarget: state.customTarget.clamp(1, math.max(1, startLimit - 1)),
      quitCompletely: startLimit == 1 || state.quitCompletely,
      errorMessage: () => null,
    );
  }

  void setStepDays(int value) => state = state.copyWith(
    stepDays: value.clamp(
      PlanValidation.minStepDays,
      PlanValidation.maxStepDays,
    ),
    errorMessage: () => null,
  );

  void setQuitCompletely({required bool quitCompletely}) {
    if (!quitCompletely && state.startLimit < 2) return;
    state = state.copyWith(
      quitCompletely: quitCompletely,
      errorMessage: () => null,
    );
  }

  void setCustomTarget(int value) => state = state.copyWith(
    customTarget: value.clamp(1, state.startLimit - 1),
    errorMessage: () => null,
  );

  void setStartDay(LogicalDay day) =>
      state = state.copyWith(startDay: day, errorMessage: () => null);

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
}
