import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for a trigger first (unless turned off), then saves a log of
/// [habitId]. Dismissing the trigger sheet cancels the log. Returns whether a
/// log was saved.
Future<bool> logNow(
  BuildContext context,
  WidgetRef ref, {
  required int habitId,
}) async {
  final habit = ref.read(habitProvider(habitId));
  if (habit == null) return false;
  unawaited(HapticFeedback.mediumImpact());
  final loggedAt = ref.read(clockProvider).now();
  final settings = ref.read(currentSettingsProvider);

  Trigger? trigger;
  String? note;
  if (settings.askForTrigger) {
    final firstPrompt = !settings.triggerPromptIntroSeen;
    final answer = await showTriggerSheet(
      context,
      habitId: habitId,
      offerToStopAsking: firstPrompt,
    );
    if (answer == null || !context.mounted) return false;
    trigger = answer.trigger;
    note = answer.note;
    if (firstPrompt) {
      await ref
          .read(settingsActionsProvider)
          .update(
            (s) => s.copyWith(
              triggerPromptIntroSeen: true,
              askForTrigger: answer.keepAsking,
            ),
          );
      if (!context.mounted) return false;
    }
  }

  final result = await ref.read(addHabitLogProvider)(
    AddHabitLogInput(
      habitId: habitId,
      loggedAt: loggedAt,
      trigger: trigger,
      note: note,
    ),
  );
  if (!context.mounted) return false;
  switch (result) {
    case Success(value: final HabitLog log):
      showAppSnackBar(
        context,
        message: 'Logged at ${AppFormat.time(log.loggedAt)}',
        actionLabel: 'Undo',
        onAction: () => ref.read(deleteHabitLogProvider)(log.id),
        duration: const Duration(seconds: 2),
      );
      return true;
    case FailureResult(:final failure):
      showAppSnackBar(
        context,
        message: failureMessage(failure),
        tone: SnackTone.danger,
      );
      return false;
  }
}
