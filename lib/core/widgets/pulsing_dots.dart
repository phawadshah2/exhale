import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primaryContainer;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: _opacity(i)),
              ),
            ),
        ],
      ),
    );
  }

  double _opacity(int index) {
    final phase = (_controller.value - index / 3) % 1;
    return 0.25 + 0.75 * math.sin(phase * math.pi).abs();
  }
}
