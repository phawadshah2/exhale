import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/backward_pager.dart';
import 'package:exhale/features/home/presentation/widgets/day_triggers.dart';
import 'package:exhale/features/home/presentation/widgets/progress_ring.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected day's count against its limit. Swipe the ring, or use the
/// arrows, to move between days from [earliestDayProvider] up to today.
class RingCard extends ConsumerWidget {
  const RingCard({required this.habitId, super.key});

  final int habitId;

  static const double _ringSize = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final habit = ref.watch(habitProvider(habitId))?.habit;
    if (history == null || habit == null) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final earliest = ref.watch(earliestDayProvider(habitId));
    final day = ref.watch(ringShownDayProvider(habitId));
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: day)))
        .value;
    final isToday = day == today;
    final beforePlan = day.isBefore(history.firstDay);
    final page = today.daysSince(day);
    final pageCount = today.daysSince(earliest) + 1;
    final picker = ref.read(ringDayProvider(habitId).notifier);
    final logs = ref.watch(logsForDayProvider((habitId: habitId, day: day)));

    void step(int days) {
      unawaited(HapticFeedback.selectionClick());
      picker.pick(day.addDays(days));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Today shows a badge and other days a chip; a fixed height
              // keeps the card from shifting when switching between them.
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Icon(AppIcons.breath, color: colors.primary, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isToday
                            ? "Today's Consumption"
                            : AppFormat.weekdayDate(day),
                        style: text.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isToday)
                      _TodayChip(onTap: picker.showToday)
                    else if (progress != null)
                      StatusBadge(
                        label: progress.badgeLabel(habit),
                        colors: progress.status.colors(context),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: _ringSize,
              child: Stack(
                children: [
                  BackwardPager(
                    pageCount: pageCount,
                    page: page,
                    onPageChanged: (index) =>
                        picker.pick(today.addDays(-index)),
                    itemBuilder: (context, index) => _DayRing(
                      habitId: habitId,
                      day: today.addDays(-index),
                      history: history,
                      habit: habit,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StepButton(
                      icon: AppIcons.back,
                      tooltip: 'Previous day',
                      onPressed: page < pageCount - 1 ? () => step(-1) : null,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _StepButton(
                      icon: AppIcons.chevronRight,
                      tooltip: 'Next day',
                      onPressed: page > 0 ? () => step(1) : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Days with more or fewer triggers ease the card to its height.
              child: AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only once the ring has finished filling.
                    _Reveal(
                      delay: AppMotion.fill + const Duration(milliseconds: 200),
                      show:
                          isToday &&
                          progress != null &&
                          progress.status == LimitStatus.over,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _OverNote(
                          tomorrowLimit: history.limitOn(day.addDays(1)),
                        ),
                      ),
                    ),
                    _Reveal(
                      show: isToday && progress != null && progress.count == 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _Note(
                          label: progress == null
                              ? ''
                              : progress.limit == 0
                              ? habit.freeLabel == null
                                    ? 'None so far today.'
                                    : '${habit.freeTitle} so far today.'
                              : 'No ${habit.units} logged today. Nice start.',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(
                      color: colors.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Fade(
                      id: isToday
                          ? 'today'
                          : '${day.year}-${day.month}-${day.day}',
                      child: Column(
                        children: [
                          if (isToday)
                            _TodayDetails(
                              habitId: habitId,
                              history: history,
                              today: today,
                              habit: habit,
                            )
                          else if (beforePlan)
                            _Details(
                              left: (AppIcons.trendDown, 'Limit', 'None yet'),
                              right: (
                                AppIcons.calendar,
                                'Plan started',
                                AppFormat.monthDay(history.firstDay),
                              ),
                            )
                          else if (progress != null)
                            _Details(
                              left: (
                                AppIcons.trendDown,
                                'Limit that day',
                                '${progress.limit} ${habit.units}',
                              ),
                              right: (
                                AppIcons.checkCircle,
                                'Status',
                                progress.badgeLabel(habit),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!beforePlan) ...[
                      _Reveal(
                        show: logs.value?.isNotEmpty ?? false,
                        child: const SizedBox(height: AppSpacing.md),
                      ),
                      DayTriggers(
                        habitId: habitId,
                        day: day,
                        onSelect: (trigger) => openLogs(
                          context,
                          LogsQuery(
                            habitId: habitId,
                            from: day,
                            to: day,
                            trigger: trigger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One page of the pager: the ring for [day].
class _DayRing extends ConsumerWidget {
  const _DayRing({
    required this.habitId,
    required this.day,
    required this.history,
    required this.habit,
  });

  final int habitId;
  final LogicalDay day;
  final PlanHistory history;
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: day)))
        .value;
    if (progress == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final beforePlan = day.isBefore(history.firstDay);
    return Center(
      child: ProgressRing(
        progress: beforePlan ? null : progress,
        child: beforePlan
            ? _BeforePlanCentre(count: progress.count)
            : _RingCentre(
                progress: progress,
                habit: habit,
                isToday: day == ref.watch(todayProvider),
              ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: context.colors.onSurfaceVariant,
      disabledColor: context.colors.outlineVariant,
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.16),
      shape: StadiumBorder(
        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutterSm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                'Today',
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
              Icon(AppIcons.backToToday, size: 14, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayDetails extends ConsumerWidget {
  const _TodayDetails({
    required this.habitId,
    required this.history,
    required this.today,
    required this.habit,
  });

  final int habitId;
  final PlanHistory history;
  final LogicalDay today;
  final Habit habit;

  String _nextTarget() {
    final plan = history.planOn(today);
    final days = plan.daysUntilNextDrop(today);
    if (days == null) return habit.freeTitle;
    final next = plan.limitOn(plan.nextDropOn(today)!);
    return next == 0
        ? (days == 1 ? 'Quit day tomorrow' : 'Quit day in ${days}d')
        : (days == 1
              ? 'Drops to $next tomorrow'
              : 'Drops to $next in ${days}d');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final latest = ref.watch(latestLogProvider(habitId)).value;

    final String entry;
    if (latest == null) {
      entry = today == history.firstDay ? 'Plan started today' : 'No logs yet';
    } else {
      final elapsed = now.difference(latest.loggedAt);
      final since = elapsed.isNegative ? Duration.zero : elapsed;
      entry = since.inMinutes < 1
          ? AppFormat.elapsed(since)
          : '${AppFormat.elapsed(since)} ago';
    }

    final _Cell right;
    if (latest == null) {
      right = (AppIcons.trendDown, 'Next target', _nextTarget());
    } else {
      right = (
        AppIcons.stress,
        'Last trigger',
        latest.trigger?.label ?? 'None',
      );
    }
    return _Details(left: (AppIcons.clock, 'Last entry', entry), right: right);
  }
}

typedef _Cell = (IconData icon, String label, String value);

class _Details extends StatelessWidget {
  const _Details({required this.left, required this.right});

  final _Cell left;
  final _Cell right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _InfoCell(cell: left)),
        Expanded(child: _InfoCell(cell: right)),
      ],
    );
  }
}

class _RingCentre extends StatelessWidget {
  const _RingCentre({
    required this.progress,
    required this.habit,
    required this.isToday,
  });

  final DailyProgress progress;
  final Habit habit;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final percent = progress.limit == 0
        ? null
        : (progress.count / progress.limit * 100).round();

    final (headline, caption, color) = switch (progress.status) {
      LimitStatus.under when progress.limit == 0 => (
        habit.freeDayTitle,
        'Keep it going',
        context.exhale.success.foreground,
      ),
      LimitStatus.under => (
        isToday
            ? '${progress.remaining} left today'
            : '${progress.remaining} under limit',
        '$percent% of ${isToday ? 'daily' : "that day's"} limit',
        colors.primary,
      ),
      LimitStatus.at => (
        'Limit reached',
        'You can still log.',
        context.exhale.warning.foreground,
      ),
      LimitStatus.over => (
        '${progress.overBy} over limit',
        percent == null
            ? (isToday ? 'Target is 0 today' : 'Target was 0')
            : '$percent% of ${isToday ? 'daily' : "that day's"} limit',
        context.exhale.danger.foreground,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          key: const Key('day-count'),
          TextSpan(
            children: [
              TextSpan(text: '${progress.count}', style: text.displayLarge),
              TextSpan(
                text: ' / ${progress.limit}',
                style: text.headlineMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(headline, style: text.titleLarge?.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          caption,
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BeforePlanCentre extends StatelessWidget {
  const _BeforePlanCentre({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', key: const Key('day-count'), style: text.displayLarge),
        Text(
          'Before your plan',
          style: text.titleLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          'No limit yet',
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _OverNote extends StatelessWidget {
  const _OverNote({required this.tomorrowLimit});

  final int tomorrowLimit;

  @override
  Widget build(BuildContext context) {
    final danger = context.exhale.danger.foreground;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: danger.withValues(alpha: 0.3)),
      ),
      child: Text(
        'A harder day. Tomorrow starts fresh at $tomorrowLimit, and your '
        'streak picks up again from there.',
        style: context.textTheme.bodyMedium,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.exhale.success.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(child: Text(label, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.cell});

  final _Cell cell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final (icon, label, value) = cell;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              Text(value, style: text.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Eases [child] in and out: the space opens or closes while it fades, so
/// nothing pops in. With a [delay], showing waits that long (hiding does
/// not), e.g. for a ring to finish filling first.
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.show,
    required this.child,
    this.delay = Duration.zero,
  });

  final bool show;
  final Widget child;
  final Duration delay;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  Timer? _timer;
  late bool _visible = widget.show && widget.delay == Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.show && !_visible) _scheduleShow();
  }

  @override
  void didUpdateWidget(_Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show == oldWidget.show) return;
    _timer?.cancel();
    if (!widget.show) {
      _visible = false;
    } else if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _scheduleShow();
    }
  }

  void _scheduleShow() => _timer = Timer(widget.delay, () {
    if (mounted) setState(() => _visible = true);
  });

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: smoothSwitcherLayout,
      child: _visible
          ? KeyedSubtree(key: const ValueKey('shown'), child: widget.child)
          : const SizedBox(key: ValueKey('hidden'), width: double.infinity),
    ),
  );
}

/// Cross-fades [child] when [id] changes, for content that differs by day.
class _Fade extends StatelessWidget {
  const _Fade({required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    layoutBuilder: smoothSwitcherLayout,
    child: KeyedSubtree(key: ValueKey(id), child: child),
  );
}
