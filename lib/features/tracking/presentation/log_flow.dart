import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for a trigger first (unless turned off), then saves the log.
/// Dismissing the trigger sheet cancels the log.
Future<void> logNow(BuildContext context, WidgetRef ref) async {
  unawaited(HapticFeedback.mediumImpact());
  final loggedAt = ref.read(clockProvider).now();
  final settings = ref.read(currentSettingsProvider);

  SmokeTrigger? trigger;
  if (settings.askForTrigger) {
    final firstPrompt = !settings.triggerPromptIntroSeen;
    final answer = await showTriggerSheet(
      context,
      offerToStopAsking: firstPrompt,
    );
    if (answer == null || !context.mounted) return;
    trigger = answer.trigger;
    if (firstPrompt) {
      await ref
          .read(settingsActionsProvider)
          .update(
            (s) => s.copyWith(
              triggerPromptIntroSeen: true,
              askForTrigger: answer.keepAsking,
            ),
          );
      if (!context.mounted) return;
    }
  }

  final result = await ref.read(logSmokeProvider)(
    LogSmokeInput(loggedAt: loggedAt, trigger: trigger),
  );
  if (!context.mounted) return;
  switch (result) {
    case Success(value: final SmokeLog log):
      showAppSnackBar(
        context,
        message: 'Logged at ${AppFormat.time(log.loggedAt)}',
        actionLabel: 'Undo',
        onAction: () => ref.read(deleteSmokeLogProvider)(log.id),
        duration: const Duration(seconds: 2),
      );
    case FailureResult(:final failure):
      showAppSnackBar(
        context,
        message: failureMessage(failure),
        tone: SnackTone.danger,
      );
  }
}
