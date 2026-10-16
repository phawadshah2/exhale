import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// The Exhale breath-spiral mark from the splash design.
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 200, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LogoPainter(
          ring: colors.primaryContainer,
          start: colors.secondaryContainer,
          end: colors.primaryContainer,
          inner: colors.primary,
          dot: colors.onSurface,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({
    required this.ring,
    required this.start,
    required this.end,
    required this.inner,
    required this.dot,
  });

  final Color ring;
  final Color start;
  final Color end;
  final Color inner;
  final Color dot;

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawCircle(
        center,
        r * 0.98,
        ringPaint..color = ring.withValues(alpha: 0.14),
      )
      ..drawCircle(
        center,
        r * 0.82,
        ringPaint..color = ring.withValues(alpha: 0.22),
      );

    void arc(
      double radius,
      double width,
      double startDeg,
      double sweepDeg,
      Paint paint,
    ) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _rad(startDeg),
        _rad(sweepDeg),
        false,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final outerRect = Rect.fromCircle(center: center, radius: r * 0.55);
    arc(
      r * 0.55,
      r * 0.065,
      -88,
      300,
      Paint()
        ..shader = SweepGradient(
          startAngle: _rad(-88),
          endAngle: _rad(212),
          colors: [end, start],
          transform: GradientRotation(_rad(-90)),
        ).createShader(outerRect),
    );
    arc(
      r * 0.36,
      r * 0.05,
      110,
      250,
      Paint()..color = end.withValues(alpha: 0.55),
    );
    arc(
      r * 0.17,
      r * 0.045,
      200,
      270,
      Paint()..color = inner.withValues(alpha: 0.85),
    );
    canvas.drawCircle(center, r * 0.035, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.ring != ring ||
      old.start != start ||
      old.end != end ||
      old.inner != inner ||
      old.dot != dot;
}
