import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Edge { wake, bed }

/// Wake and bed times on a day arc, with an inline wheel for the selected
/// one. A change that leaves under [DayWindow.minAwakeMinutes] awake is not
/// reported, and the wheel snaps back when it stops.
class DayWindowPicker extends StatefulWidget {
  const DayWindowPicker({
    required this.window,
    required this.onChanged,
    super.key,
  });

  final DayWindow window;
  final ValueChanged<DayWindow> onChanged;

  @override
  State<DayWindowPicker> createState() => _DayWindowPickerState();
}

class _DayWindowPickerState extends State<DayWindowPicker> {
  static const int _minuteInterval = 15;

  _Edge _edge = _Edge.wake;

  /// Bumped to rebuild the wheel at the last valid time.
  int _wheel = 0;
  bool _refused = false;

  int _minuteOf(_Edge edge) =>
      edge == _Edge.wake ? widget.window.wakeMinute : widget.window.bedMinute;

  void _select(_Edge edge) {
    if (edge == _edge) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _edge = edge;
      _refused = false;
      _wheel++;
    });
  }

  void _spun(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    final next = _edge == _Edge.wake
        ? DayWindow(wakeMinute: minute, bedMinute: widget.window.bedMinute)
        : DayWindow(wakeMinute: widget.window.wakeMinute, bedMinute: minute);
    if (!next.isValid) {
      _refused = true;
      return;
    }
    _refused = false;
    if (next == widget.window) return;
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(next);
  }

  bool _settled(ScrollNotification notification) {
    if (notification is ScrollEndNotification && _refused) {
      _refused = false;
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _wheel++);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final colors = context.colors;
    final minute = _minuteOf(_edge);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _DayArc(awakeMinutes: window.awakeMinutes),
          ),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: _TimeTile(
                icon: AppIcons.morning,
                label: OnboardingCopy.wakeUp,
                minute: window.wakeMinute,
                selected: _edge == _Edge.wake,
                onTap: () => _select(_Edge.wake),
              ),
            ),
            Expanded(
              child: _TimeTile(
                icon: AppIcons.lateNight,
                label: OnboardingCopy.bedtime,
                minute: window.bedMinute,
                selected: _edge == _Edge.bed,
                onTap: () => _select(_Edge.bed),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 176,
            child: NotificationListener<ScrollNotification>(
              onNotification: _settled,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: context.textTheme.titleLarge
                        ?.copyWith(color: colors.onSurface),
                  ),
                ),
                child: CupertinoDatePicker(
                  key: ValueKey((_edge, _wheel)),
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: _minuteInterval,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    minute ~/ 60,
                    minute % 60,
                  ),
                  onDateTimeChanged: _spun,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.minute,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int minute;
  final bool selected;
  final VoidCallback onTap;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final accent = colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.14)
                : context.theme.cardTheme.color ?? colors.surfaceContainerLow,
            borderRadius: _radius,
            border: Border.all(
              color: selected ? accent : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 6,
                children: [
                  Icon(icon, size: 15, color: colors.onSurfaceVariant),
                  Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppFormat.time(DateTime(2000, 1, 1, minute ~/ 60, minute % 60)),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A half-circle track with dots along it, a filled dot at wake and a ring
/// at bed, and the time awake in the middle.
class _DayArc extends StatelessWidget {
  const _DayArc({required this.awakeMinutes});

  final int awakeMinutes;

  static const double _width = 300;
  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(
                track: colors.surfaceContainerHighest,
                dots: context.exhale.emphasis,
                background: colors.surface,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 62,
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  TextSpan(
                    text: OnboardingCopy.awakeDuration(awakeMinutes),
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: ' ${OnboardingCopy.awake}',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.track,
    required this.dots,
    required this.background,
  });

  final Color track;
  final Color dots;
  final Color background;

  static const double _inset = 24;
  static const double _thickness = 14;
  static const double _dotGap = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - 2 * _inset) / 2;
    final center = Offset(size.width / 2, size.height - 10);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round,
    );

    final steps = (math.pi * radius / _dotGap).floor();
    final dot = Paint()..color = dots;
    for (var i = 1; i < steps; i++) {
      final angle = math.pi + math.pi * i / steps;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        1.6,
        dot,
      );
    }

    final wake = center + Offset(-radius, 0);
    final bed = center + Offset(radius, 0);
    canvas
      ..drawCircle(wake, 8, dot)
      ..drawCircle(bed, 8, Paint()..color = background)
      ..drawCircle(
        bed,
        8,
        Paint()
          ..color = dots
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.dots != dots ||
      oldDelegate.background != background;
}
