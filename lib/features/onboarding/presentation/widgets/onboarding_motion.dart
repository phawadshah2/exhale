import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Onboarding selects in the emphasis colour (ink in light, the accent in
/// dark), so a pick reads like the buttons and Exhale's bubbles.
@immutable
class SelectionColors {
  const SelectionColors._({
    required this.foreground,
    required this.fill,
    required this.line,
    required this.idleLine,
    required this.idleFill,
  });

  factory SelectionColors.of(BuildContext context) {
    final colors = context.colors;
    final emphasis = context.exhale.emphasis;
    final isDark = context.theme.brightness == Brightness.dark;
    return SelectionColors._(
      foreground: emphasis,
      fill: emphasis.withValues(alpha: isDark ? 0.14 : 0.06),
      line: emphasis,
      idleLine: colors.outlineVariant,
      idleFill: context.theme.cardTheme.color ?? colors.surfaceContainerLow,
    );
  }

  final Color foreground;
  final Color fill;
  final Color line;
  final Color idleLine;
  final Color idleFill;
}

/// Fades and lifts [child] in when its step appears. Children of one step
/// come in one after another, ordered by [index], once the page has mostly
/// slid in.
class StepReveal extends StatefulWidget {
  const StepReveal({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  static const Duration _lead = Duration(milliseconds: 160);
  static const Duration _stagger = Duration(milliseconds: 70);
  static const Duration _each = Duration(milliseconds: 520);

  @override
  State<StepReveal> createState() => _StepRevealState();
}

class _StepRevealState extends State<StepReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay =
        StepReveal._lead + StepReveal._stagger * widget.index.clamp(0, 8);
    final total = delay + StepReveal._each;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _progress.value) * 18),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// Shrinks [child] a little while a finger is down on it.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, super.key});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.96 : 1,
      duration: Duration(milliseconds: _down ? 90 : 220),
      curve: _down ? Curves.easeOut : Curves.easeOutBack,
      child: widget.child,
    ),
  );
}

/// [value] as text that rolls up when it grows and down when it shrinks.
class RollingNumber extends StatefulWidget {
  const RollingNumber({required this.value, this.style, super.key});

  final int value;
  final TextStyle? style;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  bool _up = true;

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _up = widget.value > old.value;
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) {
      final incoming = child.key == ValueKey(widget.value);
      final from = (incoming == _up) ? 0.45 : -0.45;
      return ClipRect(
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, from),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      );
    },
    child: Text(
      '${widget.value}',
      key: ValueKey(widget.value),
      style: widget.style,
    ),
  );
}

/// A whole number that counts up from zero the first time, then glides
/// from its last value whenever [value] changes.
class CountTo extends StatelessWidget {
  const CountTo({required this.value, required this.builder, super.key});

  final int value;
  final Widget Function(BuildContext context, int shown) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, shown, _) => builder(context, shown.round()),
  );
}
