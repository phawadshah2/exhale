import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/circle_icon_button.dart';
import 'package:exhale/core/widgets/load_failure.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_calendar_card.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_rail_card.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_trigger_card.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A habit's logs: pick a period and a day, and read that day's rail.
class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({required this.query, super.key});

  final LogsQuery query;

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  late LogsSelection _selection;

  /// The last selection with its data. A new period takes a moment to load,
  /// and this stays up until it has, rather than a spinner for a frame.
  ({LogsSelection selection, LogsView view})? _shown;

  @override
  void initState() {
    super.initState();
    final query = widget.query;
    _selection = LogsSelection.fromQuery(query, today: ref.read(todayProvider));
  }

  void _change(LogsSelection selection) =>
      setState(() => _selection = selection);

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
    final today = ref.watch(todayProvider);
    final insets = MediaQuery.paddingOf(context);
    final range = _selection.period;
    if (habitId != null) {
      final view = ref.watch(
        logsViewProvider((habitId: habitId, range: range)),
      );
      if (view != null) {
        _shown = (selection: _selection, view: view);
      }
    }
    final shown = _shown;
    final earliest = habitId == null
        ? today
        : ref.watch(earliestDayProvider(habitId));
    final failed =
        ref.watch(activeHabitsProvider).failedToLoad ||
        (habitId != null &&
            (ref
                    .watch(
                      logsInRangeProvider((habitId: habitId, range: range)),
                    )
                    .failedToLoad ||
                ref.watch(planHistoryProvider(habitId)).failedToLoad));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: AppSpacing.page.copyWith(top: insets.top + AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleIconButton(
                    tooltip: 'Back',
                    icon: AppIcons.back,
                    onPressed: () => context.pop(),
                  ),
                  CircleIconButton(
                    tooltip: 'Add a missed log',
                    icon: AppIcons.add,
                    onPressed: habitId == null
                        ? null
                        : () => showLogEditorSheet(
                            context,
                            habitId: habitId,
                            day: _selection.selected,
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (failed)
            SliverFillRemaining(
              hasScrollBody: false,
              child: LoadFailure(
                message: "Couldn't load your logs.",
                onRetry: () {
                  ref.invalidate(activeHabitsProvider);
                  if (habitId == null) return;
                  ref
                    ..invalidate(
                      logsInRangeProvider((habitId: habitId, range: range)),
                    )
                    ..invalidate(planHistoryProvider(habitId));
                },
              ),
            )
          else if (shown == null || habitId == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else
            SliverPadding(
              padding: AppSpacing.page.copyWith(
                top: AppSpacing.md,
                bottom: insets.bottom + AppSpacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  const ScrollReveal(child: _Header()),
                  const SizedBox(height: AppSpacing.md),
                  ScrollReveal(
                    index: 1,
                    child: LogsCalendarCard(
                      selection: shown.selection,
                      view: shown.view,
                      today: today,
                      earliest: earliest,
                      onChanged: _change,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ScrollReveal(
                    index: 2,
                    child: LogsTriggerCard(
                      selection: shown.selection,
                      view: shown.view,
                      today: today,
                      onTrigger: (trigger) =>
                          _change(shown.selection.toggleTrigger(trigger)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ScrollReveal(
                    index: 3,
                    child: LogsRailCard(
                      habitId: habitId,
                      selection: shown.selection,
                      view: shown.view,
                      today: today,
                      onEdit: (log) => showLogEditorSheet(
                        context,
                        habitId: habitId,
                        day: shown.selection.selected,
                        log: log,
                      ),
                      onDelete: (log) => _delete(habitId, log),
                      onSelect: (day) => _change(shown.selection.select(day)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text('The evidence.', style: text.headlineLarge),
        Text(
          'You logged it, so it counts. Pick a day, any day.',
          style: text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
