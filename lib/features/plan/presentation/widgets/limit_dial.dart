import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets a daily limit by dragging a ring or with − and +. A full ring is
/// [scaleFor]; a drag stops at both ends instead of wrapping.
class LimitDial extends StatefulWidget {
  const LimitDial({
    required this.value,
    required this.planStartLimit,
    required this.onChanged,
    required this.unitsLabel,
    required this.gapLabel,
    super.key,
  });

  final int value;
  final int planStartLimit;
  final ValueChanged<int> onChanged;

  /// "sessions a day", already singular at 1.
  final String unitsLabel;

  /// "One every 1 h 47 min"; hidden when null.
  final String? gapLabel;

  static const double _size = 220;
  static const double _radius = 96;
  static const double _strokeWidth = 14;
  static const double _thumbRadius = 14;

  /// How far from the ring's centre line a touch still takes the ring, so the
  /// page scrolls from the middle of the dial.
  static const double _ringReach = 30;

  /// Space for the text inside the ring.
  static const double _centreWidth = 150;

  /// The smallest multiple of 20 at least the larger of the two.
  static int scaleFor({required int planStartLimit, required int value}) =>
      (math.max(planStartLimit, value) / 20).ceil() * 20;

  @override
  State<LimitDial> createState() => _LimitDialState();
}

class _LimitDialState extends State<LimitDial> {
  /// The scale for the whole drag, because a lower value can shrink it and
  /// the ring must not move under the finger.
  int? _dragScale;

  /// The value the last drag event gave, ahead of the page's rebuild.
  int _dragValue = 0;

  int get _scale =>
      _dragScale ??
      LimitDial.scaleFor(
        planStartLimit: widget.planStartLimit,
        value: widget.value,
      );

  void _emit(int next) {
    if (next == widget.value) return;
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(next);
  }

  void _step(int delta) => _emit(widget.value + delta);

  /// Where a position sits on the ring, from 1 to [scale].
  int _valueAt(Offset position, int scale) {
    const centre = LimitDial._size / 2;
    final angle = math.atan2(position.dx - centre, centre - position.dy);
    final turn = (angle / (2 * math.pi)) % 1;
    return (turn * scale).round().clamp(1, scale);
  }

  bool _isOnRing(Offset position) {
    const centre = Offset(LimitDial._size / 2, LimitDial._size / 2);
    final fromLine = (position - centre).distance - LimitDial._radius;
    return fromLine.abs() <= LimitDial._ringReach;
  }

  void _start(DragStartDetails details) {
    final scale = _scale;
    final next = _valueAt(details.localPosition, scale);
    setState(() => _dragScale = scale);
    _dragValue = next;
    _emit(next);
  }

  void _update(DragUpdateDetails details) {
    final scale = _dragScale;
    if (scale == null) return;
    var next = _valueAt(details.localPosition, scale);
    // A jump of over half the ring is the finger crossing the top.
    if ((next - _dragValue).abs() > scale / 2) {
      next = _dragValue > scale / 2 ? scale : 1;
    }
    _dragValue = next;
    _emit(next);
  }

  void _end() => setState(() => _dragScale = null);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final value = widget.value;
    final canIncrease = value < PlanValidation.maxStartLimit;
    final canDecrease = value > PlanValidation.minStartLimit;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return Semantics(
      slider: true,
      label: 'Daily limit',
      value: '$value ${widget.unitsLabel}',
      increasedValue: canIncrease ? '${value + 1}' : null,
      decreasedValue: canDecrease ? '${value - 1}' : null,
      onIncrease: canIncrease ? () => _step(1) : null,
      onDecrease: canDecrease ? () => _step(-1) : null,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          RawGestureDetector(
            gestures: {
              _RingDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<_RingDragRecognizer>(
                    () => _RingDragRecognizer(isOnRing: _isOnRing),
                    (recognizer) => recognizer
                      ..onStart = _start
                      ..onUpdate = _update
                      ..onEnd = ((_) => _end())
                      ..onCancel = _end,
                  ),
            },
            child: SizedBox.square(
              dimension: LimitDial._size,
              child: CustomPaint(
                painter: _DialPainter(
                  fill: value / _scale,
                  track: colors.surfaceContainerHigh,
                  color: colors.primaryContainer,
                  thumb:
                      context.theme.cardTheme.color ??
                      colors.surfaceContainerLow,
                ),
                child: Center(
                  child: SizedBox(
                    width: LimitDial._centreWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 2,
                      children: [
                        MediaQuery.withNoTextScaling(
                          child: Text(
                            '$value',
                            style: text.displayLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        _CentreLabel(widget.unitsLabel, style: muted),
                        if (widget.gapLabel case final gap?)
                          _CentreLabel(gap, style: muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.md,
            children: [
              RoundIconButton(
                icon: AppIcons.remove,
                label: 'Fewer',
                size: 44,
                onTap: canDecrease ? () => _step(-1) : null,
              ),
              Flexible(
                child: Text(
                  'Drag the ring, or tap',
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              ),
              RoundIconButton(
                icon: AppIcons.add,
                label: 'More',
                size: 44,
                onTap: canIncrease ? () => _step(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One line that shrinks to fit inside the ring, however large the text.
class _CentreLabel extends StatelessWidget {
  const _CentreLabel(this.label, {required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, maxLines: 1, style: style),
  );
}

/// Takes a touch on the ring at once, so the page around it can't scroll it
/// away. A plain pan loses vertical drags to the page, which needs less
/// movement to win.
class _RingDragRecognizer extends PanGestureRecognizer {
  _RingDragRecognizer({required this.isOnRing}) {
    dragStartBehavior = DragStartBehavior.down;
  }

  final bool Function(Offset position) isOnRing;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      isOnRing(event.localPosition) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.fill,
    required this.track,
    required this.color,
    required this.thumb,
  });

  final double fill;
  final Color track;
  final Color color;
  final Color thumb;

  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = LimitDial._radius;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * fill;

    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = LimitDial._strokeWidth
          ..color = track,
      )
      ..drawArc(
        rect,
        _start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = LimitDial._strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );

    final thumbCenter =
        center +
        Offset(
          radius * math.cos(_start + sweep),
          radius * math.sin(_start + sweep),
        );
    canvas
      ..drawCircle(thumbCenter, LimitDial._thumbRadius, Paint()..color = thumb)
      ..drawCircle(
        thumbCenter,
        LimitDial._thumbRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.fill != fill ||
      old.track != track ||
      old.color != color ||
      old.thumb != thumb;
}
