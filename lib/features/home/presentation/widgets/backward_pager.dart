import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A horizontal pager whose page 0 is the newest; swiping right goes back.
///
/// It follows [page] when that changes from outside: one step animates and
/// longer moves jump, so no in-between page is ever reported.
class BackwardPager extends StatefulWidget {
  const BackwardPager({
    required this.pageCount,
    required this.page,
    required this.onPageChanged,
    required this.itemBuilder,
    super.key,
  });

  final int pageCount;
  final int page;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<BackwardPager> createState() => _BackwardPagerState();
}

class _BackwardPagerState extends State<BackwardPager> {
  late final PageController _controller = PageController(
    initialPage: widget.page,
  );
  late int _current = widget.page;

  @override
  void didUpdateWidget(BackwardPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.page;
    if (target == _current || !_controller.hasClients) return;
    _current = target;
    if ((target - (_controller.page ?? target).round()).abs() == 1) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpToPage(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      reverse: true,
      itemCount: widget.pageCount,
      onPageChanged: (page) {
        if (page == _current) return;
        _current = page;
        unawaited(HapticFeedback.selectionClick());
        widget.onPageChanged(page);
      },
      itemBuilder: widget.itemBuilder,
    );
  }
}
