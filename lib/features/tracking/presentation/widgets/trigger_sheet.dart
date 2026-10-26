import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_picker.dart';
import 'package:flutter/material.dart';

/// What the trigger sheet answered: a trigger (or none when skipped), and
/// whether to keep asking on future logs.
@immutable
class TriggerAnswer {
  const TriggerAnswer({this.trigger, this.keepAsking = true});

  final Trigger? trigger;
  final bool keepAsking;
}

/// Asks what triggered a log before it is saved. Returns null when the
/// sheet is dismissed, so nothing should be logged.
///
/// With [offerToStopAsking] the sheet also lets the user turn the question
/// off for future logs (shown on the first log).
Future<TriggerAnswer?> showTriggerSheet(
  BuildContext context, {
  required HabitKind habitKind,
  bool offerToStopAsking = false,
}) => showAppSheet<TriggerAnswer>(
  context,
  builder: (context) =>
      _TriggerSheet(habitKind: habitKind, offerToStopAsking: offerToStopAsking),
);

class _TriggerSheet extends StatefulWidget {
  const _TriggerSheet({
    required this.habitKind,
    required this.offerToStopAsking,
  });

  final HabitKind habitKind;
  final bool offerToStopAsking;

  @override
  State<_TriggerSheet> createState() => _TriggerSheetState();
}

class _TriggerSheetState extends State<_TriggerSheet> {
  Trigger? _selected;
  bool _keepAsking = true;

  void _finish(Trigger? trigger) =>
      Navigator.of(context)
          .pop(TriggerAnswer(trigger: trigger, keepAsking: _keepAsking));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What triggered this one?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Spotting patterns helps you see cravings coming (optional).',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TriggerPicker(
            habitKind: widget.habitKind,
            selected: _selected,
            onChanged: (trigger) => setState(() => _selected = trigger),
          ),
          if (widget.offerToStopAsking) ...[
            const SizedBox(height: AppSpacing.md),
            Material(
              color: context.exhale.inset,
              borderRadius: AppRadius.inner,
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                value: _keepAsking,
                onChanged: (value) => setState(() => _keepAsking = value),
                title: const Text('Ask every time'),
                subtitle: const Text(
                  'Turn off to log in one tap. You can change this in '
                  'Settings.',
                ),
                activeTrackColor: colors.primaryContainer,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _selected == null ? null : () => _finish(_selected),
            child: const Text('Save'),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => _finish(null),
            child: const Text('Save without trigger'),
          ),
        ],
      ),
    );
  }
}
