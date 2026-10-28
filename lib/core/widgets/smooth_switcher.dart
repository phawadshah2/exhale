import 'package:exhale/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Stacks the outgoing child over the incoming one without letting it set
/// the size, so a parent [AnimatedSize] eases straight to the new height
/// instead of holding the larger one and jumping when the old child leaves.
Widget smoothSwitcherLayout(Widget? current, List<Widget> previous) => Stack(
  alignment: Alignment.topCenter,
  children: [
    for (final old in previous)
      Positioned(top: 0, left: 0, right: 0, child: old),
    ?current,
  ],
);

/// Cross-fades to a new [child] when its key changes. Wrap it, or a parent,
/// in an [AnimatedSize] to ease the height too.
class SmoothSwitcher extends StatelessWidget {
  const SmoothSwitcher({
    required this.child,
    this.sequential = false,
    this.resize = false,
    super.key,
  });

  /// Needs a key that changes with the content.
  final Widget child;

  /// Fades the old child out fully before the new one fades in, instead of
  /// cross-fading.
  final bool sequential;

  /// Eases its own height, so content below moves with it instead of
  /// jumping.
  final bool resize;

  // Played in reverse for the outgoing child, so (0.5, 1) fades it out over
  // the first half and the incoming child in over the second.
  static const _half = Interval(0.5, 1, curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
      duration: AppMotion.swap,
      switchInCurve: sequential
          ? _half
          : const Interval(0.3, 1, curve: Curves.easeInOut),
      switchOutCurve: sequential
          ? _half
          : const Interval(0, 0.7, curve: Curves.easeInOut),
      layoutBuilder: smoothSwitcherLayout,
      child: child,
    );
    if (!resize) return switcher;
    return AnimatedSize(
      duration: AppMotion.swap,
      curve: AppMotion.swapCurve,
      alignment: Alignment.topCenter,
      child: switcher,
    );
  }
}
