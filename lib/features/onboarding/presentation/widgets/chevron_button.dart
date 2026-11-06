import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:flutter/material.dart';

/// A full-width primary button whose three trailing chevrons nudge forward
/// while it is enabled. Still under Reduce Motion.
class ChevronButton extends StatefulWidget {
  const ChevronButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<ChevronButton> createState() => _ChevronButtonState();
}

class _ChevronButtonState extends State<ChevronButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  static const _sizes = [10.0, 13.0, 17.0];
  static const _opacities = [0.25, 0.55, 1.0];
  static const _delays = [0.0, 0.12, 0.24];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ChevronButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final moving =
        widget.onPressed != null && !MediaQuery.disableAnimationsOf(context);
    if (moving && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!moving && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onPressed,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Text(widget.label, textAlign: TextAlign.center),
              ),
              if (enabled)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: ExcludeSemantics(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Opacity(
                              opacity: _opacities[i],
                              child: Transform.translate(
                                offset: Offset(_nudge(i), 0),
                                child: Icon(
                                  AppIcons.chevronRight,
                                  size: _sizes[i],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _nudge(int i) {
    final phase = (_controller.value - _delays[i] / 1.3) % 1;
    return 4 * math.sin(math.pi * phase);
  }
}
