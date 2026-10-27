import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/day_group.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_day_card.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_period_card.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every log of a habit, grouped by day, for a week, a range or one day.
class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({required this.query, super.key});

  final LogsQuery query;

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  late PeriodRange _range;
  late bool _weekly;
  Trigger? _trigger;

  bool get _singleDay => _range.from == _range.to;

  @override
  void initState() {
    super.initState();
    final query = widget.query;
    final from = query.from;
    final to = query.to;
    _range = from != null && to != null
        ? PeriodRange(from, to)
        : PeriodRange.weekOf(ref.read(todayProvider));
    _weekly = _range == PeriodRange.weekOf(_range.from);
    _trigger = query.trigger;
  }

  void _step(int weeks) => setState(
    () => _range = PeriodRange.weekOf(_range.from.addDays(7 * weeks)),
  );

  void _clearDay() => setState(() {
    _range = PeriodRange.weekOf(_range.from);
    _weekly = true;
  });

  Future<void> _delete(int habitId, HabitLog log) async {
    final unit = ref.read(habitProvider(habitId))?.habit.unit ?? 'log';
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
    if (result case FailureResult(:final failure)) {
      showAppSnackBar(
        context,
        message: failureMessage(failure),
        tone: SnackTone.danger,
      );
      return;
    }
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
  }

  @override
  Widget build(BuildContext context) {
    final habitId = widget.query.habitId ?? ref.watch(primaryHabitProvider)?.id;
    final habit = habitId == null
        ? null
        : ref.watch(habitProvider(habitId))?.habit;
    final today = ref.watch(todayProvider);
    final view = habitId == null
        ? null
        : ref.watch(logsViewProvider((habitId: habitId, range: _range)));
    final addDay = _range.to.isAfter(today) ? today : _range.to;
    final earliest = habitId == null
        ? today
        : ref.watch(earliestDayProvider(habitId));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppSpacing.page.copyWith(top: AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _CircleButton(
                      tooltip: 'Back',
                      icon: AppIcons.back,
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Logs',
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleLarge,
                      ),
                    ),
                    _CircleButton(
                      tooltip: 'Add a missed log',
                      icon: AppIcons.add,
                      accent: true,
                      onPressed: habitId == null
                          ? null
                          : () => showLogEditorSheet(
                              context,
                              habitId: habitId,
                              day: addDay,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (view == null || habit == null || habitId == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else
              SliverPadding(
                padding: AppSpacing.page.copyWith(bottom: AppSpacing.xl),
                sliver: SliverList.list(
                  children: [
                    if (_singleDay || _trigger != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (_singleDay)
                              _FilterChip(
                                label: AppFormat.shortWeekdayDate(_range.from),
                                removeTooltip: 'Remove day filter',
                                onRemove: _clearDay,
                              ),
                            if (_trigger case final trigger?)
                              _FilterChip(
                                label: trigger.label,
                                removeTooltip: 'Remove ${trigger.label} filter',
                                onRemove: () => setState(() => _trigger = null),
                              ),
                          ],
                        ),
                      ),
                    if (_singleDay && view.days.isNotEmpty)
                      LogsDayCard(
                        entry: view.days.first,
                        today: today,
                        habit: habit,
                        trigger: _trigger,
                      )
                    else
                      LogsPeriodCard(
                        view: view,
                        range: _range,
                        today: today,
                        weekly: _weekly,
                        trigger: _trigger,
                        onPrevious: _range.from.isAfter(earliest)
                            ? () => _step(-1)
                            : null,
                        onNext: _range.to.isBefore(today)
                            ? () => _step(1)
                            : null,
                        onTrigger: (trigger) =>
                            setState(() => _trigger = trigger),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        'Newest first',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ..._groups(view, habitId, today),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Tap a log to edit · swipe left to delete',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groups(LogsView view, int habitId, LogicalDay today) {
    final trigger = _trigger;
    final groups = <Widget>[];
    for (final entry in view.days) {
      final rows = trigger == null
          ? entry.logs
          : entry.logs.where((log) => log.trigger == trigger).toList();
      if (trigger != null && rows.isEmpty) continue;
      groups.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: DayGroup(
            key: ValueKey(entry.day),
            entry: entry,
            rows: rows,
            today: today,
            onAdd: () =>
                showLogEditorSheet(context, habitId: habitId, day: entry.day),
            onEdit: (log) => showLogEditorSheet(
              context,
              habitId: habitId,
              day: entry.day,
              log: log,
            ),
            onDelete: (log) => _delete(habitId, log),
          ),
        ),
      );
    }
    if (groups.isEmpty) {
      groups.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            'No logs match.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return groups;
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.accent = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = accent ? colors.primary : colors.onSurface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent
                  ? colors.primary.withValues(alpha: 0.14)
                  : colors.surfaceContainerHigh,
              border: Border.all(
                color: accent
                    ? colors.primary.withValues(alpha: 0.45)
                    : colors.outlineVariant,
              ),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.removeTooltip,
    required this.onRemove,
  });

  final String label;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: removeTooltip,
      child: GestureDetector(
        onTap: onRemove,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: colors.primary.withValues(alpha: 0.14),
            shape: StadiumBorder(
              side: BorderSide(color: colors.primary.withValues(alpha: 0.45)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(AppIcons.close, size: 12, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
