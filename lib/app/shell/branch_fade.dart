import 'package:exhale/core/theme/app_motion.dart';
import 'package:flutter/widgets.dart';

/// Keeps every shell tab alive and eases between them: the tab being left
/// fades out while the new one fades and lifts in, at the pace of the other
/// content swaps.
class BranchFade extends StatefulWidget {
  const BranchFade({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<BranchFade> createState() => _BranchFadeState();
}

class _BranchFadeState extends State<BranchFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.swap,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.swapCurve,
  );
  int? _leaving;

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _leaving != null) {
        setState(() => _leaving = null);
      }
    });
  }

  @override
  void didUpdateWidget(BranchFade old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _leaving = null;
      return;
    }
    _leaving = old.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) {
      final t = _progress.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          for (final (i, child) in widget.children.indexed)
            // The same wrapper for every tab, so none loses its state.
            Offstage(
              offstage: i != widget.currentIndex && i != _leaving,
              child: TickerMode(
                enabled: i == widget.currentIndex || i == _leaving,
                child: IgnorePointer(
                  ignoring: i != widget.currentIndex,
                  child: Opacity(
                    opacity: i == widget.currentIndex
                        ? t
                        : i == _leaving
                        ? 1 - t
                        : 0,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        i == widget.currentIndex ? (1 - t) * 14 : 0,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
