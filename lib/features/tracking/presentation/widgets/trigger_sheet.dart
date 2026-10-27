import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// off for future logs (shown on the first log). A chip names [habitId] and
/// what today's count will be once this log is saved.
Future<TriggerAnswer?> showTriggerSheet(
  BuildContext context, {
  required int habitId,
  bool offerToStopAsking = false,
}) => showAppSheet<TriggerAnswer>(
  context,
  builder: (context) =>
      _TriggerSheet(habitId: habitId, offerToStopAsking: offerToStopAsking),
);

class _TriggerSheet extends ConsumerStatefulWidget {
  const _TriggerSheet({required this.habitId, required this.offerToStopAsking});

  final int habitId;
  final bool offerToStopAsking;

  @override
  ConsumerState<_TriggerSheet> createState() => _TriggerSheetState();
}

class _TriggerSheetState extends ConsumerState<_TriggerSheet> {
  Trigger? _selected;
  bool _keepAsking = true;

  void _finish(Trigger? trigger) =>
      Navigator.of(context)
          .pop(TriggerAnswer(trigger: trigger, keepAsking: _keepAsking));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final tracked = ref.watch(habitProvider(widget.habitId));
    if (tracked == null) return const SizedBox.shrink();
    final progress = ref
        .watch(
          dayProgressProvider((
            habitId: widget.habitId,
            day: ref.watch(todayProvider),
          )),
        )
        .value;
    final habit = tracked.habit;
    final chip = progress == null
        ? habit.name
        : '${habit.name} · ${progress.count + 1} of ${progress.limit} '
              'after this';
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: ShapeDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(habit.kind.icon, size: 14, color: colors.primary),
                  Flexible(
                    child: Text(
                      chip,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('What triggered this one?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Spotting patterns helps you see cravings coming (optional).',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TriggerPicker(
            habitKind: habit.kind,
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
