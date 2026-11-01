import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:exhale/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// A thin ring showing what is left of a gap. It moves like the day's ring,
/// filling from empty when it appears and easing to the new position when
/// [restartKey] changes; between those it follows [fraction] exactly.
class DrainingRing extends StatefulWidget {
  const DrainingRing({
    required this.fraction,
    required this.restartKey,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.track,
    super.key,
  });

  final double fraction;
  final Object restartKey;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color track;

  @override
  State<DrainingRing> createState() => _DrainingRingState();
}

class _DrainingRingState extends State<DrainingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fill,
  )..forward();

  double _from = 0;

  double _shown(double target) => lerpDouble(
    _from,
    target,
    AppMotion.fillCurve.transform(_controller.value),
  )!;

  @override
  void didUpdateWidget(DrainingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restartKey == oldWidget.restartKey) return;
    _from = _shown(oldWidget.fraction);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: DrainingRingPainter(
            fill: reduceMotion ? widget.fraction : _shown(widget.fraction),
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            track: widget.track,
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class DrainingRingPainter extends CustomPainter {
  const DrainingRingPainter({
    required this.fill,
    required this.strokeWidth,
    required this.color,
    required this.track,
  });

  final double fill;
  final double strokeWidth;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, stroke(track));
    if (fill <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fill,
      false,
      stroke(color),
    );
  }

  @override
  bool shouldRepaint(DrainingRingPainter old) =>
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.color != color ||
      old.track != track;
}
