import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Three dots that pulse in turn while Exhale "types".
class TypingDots extends StatefulWidget {
  const TypingDots({
    this.animate = true,
    this.once = false,
    this.color,
    super.key,
  });

  final bool animate;

  /// Pulse through one cycle, then rest.
  final bool once;

  /// Defaults to the emphasis colour.
  final Color? color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _restingOpacity = [1.0, 0.6, 0.3];

  @override
  void initState() {
    super.initState();
    if (widget.animate) _start();
  }

  void _start() {
    if (widget.once) {
      _controller.forward(from: 0);
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !widget.once && !_controller.isAnimating) {
      _start();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacity(int i) {
    if (!widget.animate) return _restingOpacity[i];
    // Each dot peaks a third of a cycle after the one before it.
    final phase = (_controller.value - i / 3) * 2 * math.pi;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.cos(phase));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.exhale.emphasis;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color.withValues(alpha: _opacity(i)),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
