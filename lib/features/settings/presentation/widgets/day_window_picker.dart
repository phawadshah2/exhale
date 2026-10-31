import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
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
    final pick = SelectionColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? pick.fill : pick.idleFill,
              borderRadius: _radius,
              border: Border.all(
                color: selected ? pick.line : pick.idleLine,
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
                  AppFormat.time(
                    DateTime(2000, 1, 1, minute ~/ 60, minute % 60),
                  ),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A half-circle track with dots along it, a filled dot at wake and a ring
/// at bed, and the time awake in the middle: big numbers with small units,
/// on two lines when there are minutes. The dots sweep from wake to bed
/// when it appears.
class _DayArc extends StatelessWidget {
  const _DayArc({required this.awakeMinutes});

  final int awakeMinutes;

  static const double _width = 300;
  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final hours = awakeMinutes ~/ 60;
    final minutes = awakeMinutes % 60;
    final number = text.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
      height: 1.05,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unit = text.titleMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    Widget line(int value, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 3,
      children: [
        RollingNumber(value: value, style: number),
        Text(label, style: unit),
      ],
    );

    return Semantics(
      label:
          '${OnboardingCopy.awakeDuration(awakeMinutes)} '
          '${OnboardingCopy.awake}',
      excludeSemantics: true,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.fill,
                curve: AppMotion.fillCurve,
                builder: (context, sweep, _) => CustomPaint(
                  painter: _ArcPainter(
                    sweep: sweep,
                    track: colors.surfaceContainerHighest,
                    dots: context.exhale.emphasis,
                    background: colors.surface,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  line(hours, OnboardingCopy.hourUnit),
                  AnimatedSize(
                    duration: AppMotion.swap,
                    curve: AppMotion.swapCurve,
                    child: minutes == 0
                        ? const SizedBox(width: 1)
                        : line(minutes, OnboardingCopy.minuteUnit),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    OnboardingCopy.awake,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.sweep,
    required this.track,
    required this.dots,
    required this.background,
  });

  /// How far from wake toward bed the dots have reached, 0 to 1.
  final double sweep;
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
      if (i / steps > sweep) break;
      final angle = math.pi + math.pi * i / steps;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        1.6,
        dot,
      );
    }

    final wake = center + Offset(-radius, 0);
    final bed = center + Offset(radius, 0);
    final arrived = ((sweep - 0.9) / 0.1).clamp(0.0, 1.0);
    canvas.drawCircle(wake, 8, dot);
    if (arrived == 0) return;
    canvas
      ..drawCircle(bed, 8 * arrived, Paint()..color = background)
      ..drawCircle(
        bed,
        8 * arrived,
        Paint()
          ..color = dots
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.sweep != sweep ||
      oldDelegate.track != track ||
      oldDelegate.dots != dots ||
      oldDelegate.background != background;
}
