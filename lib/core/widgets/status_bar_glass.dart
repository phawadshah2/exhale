import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

/// Lays a glass strip over the status bar once the page's main vertical
/// scroll view has moved, so content scrolling up under the clock and
/// battery stays readable. At the top of the page the strip is invisible.
///
/// Wrap the page's scrolling body; the scroll view runs edge to edge under
/// the status bar, as every page here already does.
class StatusBarGlass extends StatefulWidget {
  const StatusBarGlass({required this.child, super.key});

  final Widget child;

  /// Past this many pixels the strip is on.
  static const double threshold = 4;

  @override
  State<StatusBarGlass> createState() => _StatusBarGlassState();
}

class _StatusBarGlassState extends State<StatusBarGlass> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        notification is ScrollMetricsNotification) {
      return false;
    }
    final scrolled = notification.metrics.pixels > StatusBarGlass.threshold;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
        if (top > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: _scrolled ? 1 : 0,
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: GlassSurface(
                    radius: 0,
                    blur: 20,
                    opacity: 0.3,
                    shadow: false,
                    color: colors.brightness == Brightness.dark
                        ? colors.surface
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
