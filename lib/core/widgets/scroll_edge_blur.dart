import 'dart:ui';

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

/// Blurs whatever scrolls under the status bar, fading in once [child]
/// scrolls, like iOS navigation areas.
class ScrollEdgeBlur extends StatefulWidget {
  const ScrollEdgeBlur({required this.child, super.key});

  /// A scrollable (or a widget containing one) that runs edge to edge.
  final Widget child;

  @override
  State<ScrollEdgeBlur> createState() => _ScrollEdgeBlurState();
}

class _ScrollEdgeBlurState extends State<ScrollEdgeBlur> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final scrolled = notification.metrics.pixels > 2;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassMode.of(context);
    final height = MediaQuery.paddingOf(context).top;

    final Widget bar = glass
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ColoredBox(color: colors.surface.withValues(alpha: 0.6)),
            ),
          )
        : ColoredBox(color: colors.surface);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.35),
                      width: 0.5,
                    ),
                  ),
                ),
                child: bar,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
