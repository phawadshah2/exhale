import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/log_row.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

/// A day's header and its logs, collapsing after [collapsedRows].
class DayGroup extends StatefulWidget {
  const DayGroup({
    required this.entry,
    required this.rows,
    required this.today,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    super.key,
  });

  static const collapsedRows = 3;

  final LogsDay entry;

  /// The day's logs that pass the trigger filter, newest first.
  final List<HabitLog> rows;
  final LogicalDay today;
  final ValueChanged<HabitLog> onEdit;
  final Future<void> Function(HabitLog log) onDelete;
  final VoidCallback onAdd;

  @override
  State<DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends State<DayGroup> {
  bool _expanded = false;

  String get _title {
    final day = widget.entry.day;
    final date = AppFormat.shortWeekdayDate(day);
    return day == widget.today ? 'Today · $date' : date;
  }

  String? get _summary {
    final entry = widget.entry;
    final limit = entry.limit;
    if (limit == null) return 'Before your plan';
    final over = entry.count - limit;
    return '${entry.count} of $limit allowed'
        '${over > 0 ? ' · $over over' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final rows = widget.rows;
    final collapsed = !_expanded && rows.length > DayGroup.collapsedRows;
    final shown = collapsed ? rows.take(DayGroup.collapsedRows) : rows;
    final dot =
        widget.entry.progress?.status.colors(context).foreground ??
        colors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _title,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _summary!,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          _AddMissed(onTap: widget.onAdd)
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (final (i, log) in shown.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    Dismissible(
                      key: ValueKey(log.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await widget.onDelete(log);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: context.exhale.danger.soft,
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: Icon(
                          AppIcons.delete,
                          color: context.exhale.danger.foreground,
                        ),
                      ),
                      child: ColoredBox(
                        color: colors.surfaceContainerLow,
                        child: LogRow(
                          log: log,
                          onTap: () => widget.onEdit(log),
                        ),
                      ),
                    ),
                  ],
                  if (collapsed)
                    TextButton(
                      onPressed: () => setState(() => _expanded = true),
                      child: Text(
                        'Show ${rows.length - DayGroup.collapsedRows} more',
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AddMissed extends StatelessWidget {
  const _AddMissed({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: CustomPaint(
        painter: _DashedBorder(colors.outlineVariant),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Icon(AppIcons.add, size: 16, color: colors.onSurfaceVariant),
              Flexible(
                child: Text(
                  'Add a missed log for this day',
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.lg),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 10) {
        canvas.drawPath(metric.extractPath(at, at + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
