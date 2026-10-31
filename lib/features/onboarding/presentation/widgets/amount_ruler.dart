import 'dart:async';

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A horizontal scale with one tick per unit under a fixed centre marker.
/// The scale follows the finger, so dragging left raises the value.
class AmountRuler extends StatefulWidget {
  const AmountRuler({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  static const double tickGap = 9;
  static const double height = 64;

  @override
  State<AmountRuler> createState() => _AmountRulerState();
}

class _AmountRulerState extends State<AmountRuler> {
  /// The value under the marker while dragging, between whole units.
  double? _dragCenter;
  int _dragStart = 0;
  double _dx = 0;

  void _start(DragStartDetails _) {
    _dragStart = widget.value;
    _dx = 0;
    setState(() => _dragCenter = widget.value.toDouble());
  }

  void _update(DragUpdateDetails details) {
    const gap = AmountRuler.tickGap;
    _dx = (_dx + details.delta.dx).clamp(
      (_dragStart - widget.max) * gap,
      (_dragStart - widget.min) * gap,
    );
    final center = _dragStart - _dx / gap;
    setState(() => _dragCenter = center);
    _emit(center.round());
  }

  void _end() => setState(() => _dragCenter = null);

  void _emit(int value) {
    final next = value.clamp(widget.min, widget.max);
    if (next == widget.value) return;
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = widget.value;
    return Semantics(
      slider: true,
      value: '$value',
      increasedValue: value < widget.max ? '${value + 1}' : null,
      decreasedValue: value > widget.min ? '${value - 1}' : null,
      onIncrease: value < widget.max ? () => _emit(value + 1) : null,
      onDecrease: value > widget.min ? () => _emit(value - 1) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _start,
        onHorizontalDragUpdate: _update,
        onHorizontalDragEnd: (_) => _end(),
        onHorizontalDragCancel: _end,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0, 0.18, 0.82, 1],
          ).createShader(bounds),
          child: CustomPaint(
            size: const Size(double.infinity, AmountRuler.height),
            painter: _RulerPainter(
              center: _dragCenter ?? value.toDouble(),
              value: value,
              min: widget.min,
              max: widget.max,
              tick: colors.outlineVariant,
              marker: context.exhale.emphasis,
              label: context.textTheme.labelSmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
              current: context.textTheme.labelSmall!.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.center,
    required this.value,
    required this.min,
    required this.max,
    required this.tick,
    required this.marker,
    required this.label,
    required this.current,
  });

  final double center;
  final int value;
  final int min;
  final int max;
  final Color tick;
  final Color marker;
  final TextStyle label;
  final TextStyle current;

  static const double _tickBottom = 40;
  static const double _minor = 16;
  static const double _major = 30;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = AmountRuler.tickGap;
    final mid = size.width / 2;
    final reach = (mid / gap).ceil() + 1;
    final first = (center - reach).floor().clamp(min, max);
    final last = (center + reach).ceil().clamp(min, max);
    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 1.5;

    for (var v = first; v <= last; v++) {
      final x = mid + (v - center) * gap;
      final major = v % 5 == 0;
      canvas.drawLine(
        Offset(x, _tickBottom - (major ? _major : _minor)),
        Offset(x, _tickBottom),
        tickPaint,
      );
      if (v % 10 == 0) {
        final painter = TextPainter(
          text: TextSpan(text: '$v', style: v == value ? current : label),
          textDirection: TextDirection.ltr,
        )..layout();
        painter
          ..paint(canvas, Offset(x - painter.width / 2, _tickBottom + 6))
          ..dispose();
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(mid, (_tickBottom + 4) / 2),
          width: 3,
          height: _tickBottom + 4,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = marker,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.center != center ||
      old.value != value ||
      old.min != min ||
      old.max != max ||
      old.tick != tick ||
      old.marker != marker ||
      old.label != label ||
      old.current != current;
}
