import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A month calendar in a sheet. Returns the day picked, between [earliest] and
/// [today].
Future<LogicalDay?> showLogsDatePicker(
  BuildContext context, {
  required LogicalDay selected,
  required LogicalDay earliest,
  required LogicalDay today,
}) => showAppSheet<LogicalDay>(
  context,
  builder: (context) =>
      _DatePicker(selected: selected, earliest: earliest, today: today),
);

class _DatePicker extends StatefulWidget {
  const _DatePicker({
    required this.selected,
    required this.earliest,
    required this.today,
  });

  final LogicalDay selected;
  final LogicalDay earliest;
  final LogicalDay today;

  @override
  State<_DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<_DatePicker> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late LogicalDay _month = widget.selected.startOfMonth;

  bool get _canGoEarlier => _month.isAfter(widget.earliest.startOfMonth);

  bool get _canGoLater => _month.isBefore(widget.today.startOfMonth);

  void _move(int by) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _month = LogicalDay(_month.year, _month.month + by, 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final leading = _month.weekday - 1;
    final cells = <LogicalDay?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= _month.daysInMonth; d++)
        LogicalDay(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Text('Pick a day', style: text.titleLarge),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: _canGoEarlier ? () => _move(-1) : null,
                icon: const Icon(AppIcons.back, size: 18),
              ),
              Expanded(
                child: Text(
                  AppFormat.monthYear(_month),
                  textAlign: TextAlign.center,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: _canGoLater ? () => _move(1) : null,
                icon: const Icon(AppIcons.chevronRight, size: 18),
              ),
            ],
          ),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (final weekday in _weekdays)
                    Expanded(
                      child: Text(
                        weekday,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (var row = 0; row < cells.length ~/ 7; row++)
            Row(
              children: [
                for (final day in cells.sublist(row * 7, row * 7 + 7))
                  Expanded(
                    child: day == null
                        ? const SizedBox(height: _PickerDay.height)
                        : _PickerDay(
                            day: day,
                            selected: day == widget.selected,
                            isToday: day == widget.today,
                            enabled:
                                !day.isAfter(widget.today) &&
                                !day.isBefore(widget.earliest),
                            onTap: () => Navigator.of(context).pop(day),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PickerDay extends StatelessWidget {
  const _PickerDay({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  static const double height = 48;

  final LogicalDay day;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      label: AppFormat.monthDay(day),
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: selected
                ? BoxDecoration(
                    color: exhale.emphasis,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  )
                : const BoxDecoration(),
            child: Center(
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  '${day.day}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? exhale.onEmphasis
                        : enabled
                        ? colors.onSurface
                        : colors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: selected || isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
