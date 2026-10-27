import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds a missed log of [habitId] on [day], or edits [log] when given.
Future<void> showLogEditorSheet(
  BuildContext context, {
  required int habitId,
  required LogicalDay day,
  HabitLog? log,
}) => showAppSheet<void>(
  context,
  builder: (context) => LogEditorSheet(habitId: habitId, day: day, log: log),
);

/// The moment on [day] that [time] refers to, honouring the reset hour:
/// with a 4 AM reset, 01:30 belongs to the next calendar date.
DateTime instantOnLogicalDay(
  LogicalDay day,
  TimeOfDay time,
  DayBoundary boundary,
) {
  final date = time.hour < boundary.resetHour ? day.addDays(1) : day;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class LogEditorSheet extends ConsumerStatefulWidget {
  const LogEditorSheet({
    required this.habitId,
    required this.day,
    this.log,
    super.key,
  });

  final int habitId;
  final LogicalDay day;
  final HabitLog? log;

  @override
  ConsumerState<LogEditorSheet> createState() => _LogEditorSheetState();
}

class _LogEditorSheetState extends ConsumerState<LogEditorSheet> {
  late TimeOfDay _time;
  late Trigger? _trigger = widget.log?.trigger;
  late final TextEditingController _note = TextEditingController(
    text: widget.log?.note,
  );
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.log != null;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    if (log != null) {
      _time = TimeOfDay.fromDateTime(log.loggedAt);
    } else {
      final now = ref.read(clockProvider).now();
      final isToday = ref.read(dayBoundaryProvider).dayOf(now) == widget.day;
      _time = isToday
          ? TimeOfDay.fromDateTime(now)
          : const TimeOfDay(hour: 12, minute: 0);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showWheelPicker(
      context,
      title: 'Time',
      mode: CupertinoDatePickerMode.time,
      initial: DateTime(2000, 1, 1, _time.hour, _time.minute),
    );
    if (picked != null) setState(() => _time = TimeOfDay.fromDateTime(picked));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final loggedAt = instantOnLogicalDay(
      widget.day,
      _time,
      ref.read(dayBoundaryProvider),
    );
    final log = widget.log;
    final Result<Object?> result = log == null
        ? await ref.read(addHabitLogProvider)(
            AddHabitLogInput(
              habitId: widget.habitId,
              loggedAt: loggedAt,
              trigger: _trigger,
              note: _note.text,
            ),
          )
        : await ref.read(updateHabitLogProvider)(
            log.copyWith(
              loggedAt: loggedAt,
              trigger: () => _trigger,
              note: () => _note.text,
            ),
          );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        setState(() {
          _saving = false;
          _error = failureMessage(failure);
        });
    }
  }

  Future<void> _delete(HabitLog log) async {
    final unit = ref.read(habitProvider(widget.habitId))?.habit.unit ?? 'log';
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete this log?',
      message:
          'The $unit at ${AppFormat.time(log.loggedAt)} will be removed '
          'from this day.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final add = ref.read(addHabitLogProvider);
    final result = await ref.read(deleteHabitLogProvider)(log.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        showAppSnackBar(
          context,
          message: 'Log deleted',
          actionLabel: 'Undo',
          onAction: () => add(
            AddHabitLogInput(
              habitId: log.habitId,
              loggedAt: log.loggedAt,
              trigger: log.trigger,
              note: log.note,
            ),
          ),
        );
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        setState(() => _error = failureMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final habitName = ref.watch(habitProvider(widget.habitId))?.habit.name;
    final time = AppFormat.time(DateTime(2000, 1, 1, _time.hour, _time.minute));

    return SingleChildScrollView(
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
          Text(
            _isEdit ? 'Edit log' : 'Add missed log',
            style: text.headlineSmall,
          ),
          Text(
            [
              ?habitName,
              AppFormat.shortWeekdayDate(widget.day),
            ].join(' · '),
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: context.exhale.inset,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.inner,
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(AppIcons.clock, color: colors.primary),
              title: const Text('Time'),
              trailing: Text(time, style: text.titleLarge),
              onTap: _pickTime,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Trigger', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TriggerPicker(
            habitKind:
                ref.watch(habitProvider(widget.habitId))?.habit.kind ??
                HabitKind.custom,
            selected: _trigger,
            onChanged: (trigger) => setState(() => _trigger = trigger),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _note,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: text.bodySmall?.copyWith(
                color: context.exhale.danger.foreground,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEdit ? 'Save changes' : 'Add log'),
          ),
          if (widget.log case final log?)
            TextButton(
              onPressed: _saving ? null : () => _delete(log),
              style: TextButton.styleFrom(
                foregroundColor: context.exhale.danger.foreground,
              ),
              child: const Text('Delete this log'),
            ),
        ],
      ),
    );
  }
}
