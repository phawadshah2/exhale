import 'package:exhale/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Fades and lifts [child] in the first time it scrolls into view. Cards
/// already on screen when the page opens come in one after another, ordered
/// by [index].
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 90);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.reveal + _stagger * 4,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayFraction, 1, curve: Curves.easeOutCubic),
  );
  ScrollPosition? _position;
  bool _revealed = false;

  double get _delayFraction {
    final delay = _stagger * widget.index.clamp(0, 4);
    return delay.inMilliseconds / _controller.duration!.inMilliseconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height - 24) {
      _revealed = true;
      _position?.removeListener(_check);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _progress.value) * 28),
        child: child,
      ),
    ),
  );
}
