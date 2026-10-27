import 'dart:async';

import 'package:exhale/app/shell/app_shell.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One-time glass bubble above the + button explaining that holding it opens
/// more options. Completes when the user taps "Got it" or dismisses it.
Future<void> showLogHint(BuildContext context) {
  unawaited(HapticFeedback.lightImpact());
  return Navigator.of(context, rootNavigator: true).push<void>(_LogHintRoute());
}

class _LogHintRoute extends PopupRoute<void> {
  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss hint';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final growth = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    return Stack(
      children: [
        Positioned(
          right: AppSpacing.pageMargin,
          bottom:
              (bottomInset < 12 ? 12 : bottomInset) +
              FloatingTabBar.height +
              18,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(growth),
              alignment: Alignment.bottomRight,
              child: const _LogHintBubble(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogHintBubble extends StatelessWidget {
  const _LogHintBubble();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return AppGlass(
      radius: 26,
      frosted: true,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hold + for more', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Add a missed log, or start tracking another habit.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
