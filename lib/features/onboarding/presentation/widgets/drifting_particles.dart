import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slow, glowing dust drifting upward. One [animation] cycle (0 → 1) is a
/// seamless loop: every particle completes whole laps.
class DriftingParticles extends StatelessWidget {
  const DriftingParticles({
    required this.animation,
    required this.color,
    super.key,
  });

  final Animation<double> animation;
  final Color color;

  static final List<_Particle> _particles = _generate(28);

  static List<_Particle> _generate(int count) {
    final random = math.Random(7);
    return List.generate(
      count,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        laps: 1 + random.nextInt(2),
        swayLaps: 1 + random.nextInt(3),
        twinkleLaps: 2 + random.nextInt(4),
        radius: 1 + random.nextDouble() * 1.8,
        alpha: 0.12 + random.nextDouble() * 0.28,
        phase: random.nextDouble() * 2 * math.pi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            animation: animation,
            color: color,
            particles: _particles,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.laps,
    required this.swayLaps,
    required this.twinkleLaps,
    required this.radius,
    required this.alpha,
    required this.phase,
  });

  final double x;
  final double y;
  final int laps;
  final int swayLaps;
  final int twinkleLaps;
  final double radius;
  final double alpha;
  final double phase;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.animation,
    required this.color,
    required this.particles,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final turn = 2 * math.pi * t;
    final paint = Paint();

    for (final p in particles) {
      final y = (p.y - t * p.laps) % 1;
      final x = p.x + math.sin(turn * p.swayLaps + p.phase) * 0.025;
      final twinkle = 0.6 + 0.4 * math.sin(turn * p.twinkleLaps + p.phase);
      // Fade in at the bottom and out at the top.
      final edge = math.min(1, math.min(y, 1 - y) * 6);
      final opacity = (p.alpha * twinkle * edge).clamp(0.0, 1.0);

      paint
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.color != color || old.particles != particles;
}
