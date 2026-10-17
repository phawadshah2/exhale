import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

enum SnackTone { info, success, warning, danger }

/// Shows the app's floating capsule snackbar: it springs up from below,
/// pops its status dot, and runs a countdown bar until it closes.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackTone tone = SnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final hasAction = actionLabel != null && onAction != null;
  // Screen-reader users need time to reach the action.
  final visibleFor = hasAction && MediaQuery.accessibleNavigationOf(context)
      ? const Duration(seconds: 10)
      : duration;

  // Clear rather than queue, so the visible snackbar (and its action) is
  // always the latest one.
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        behavior: SnackBarBehavior.floating,
        duration: visibleFor,
        persist: false,
        content: AppSnackBarContent(
          message: message,
          tone: tone,
          duration: visibleFor,
          actionLabel: hasAction ? actionLabel : null,
          onAction: hasAction ? onAction : null,
        ),
      ),
      snackBarAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 300),
        reverseDuration: Duration(milliseconds: 220),
      ),
    );
}

class AppSnackBarContent extends StatefulWidget {
  const AppSnackBarContent({
    required this.message,
    required this.tone,
    required this.duration,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final SnackTone tone;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<AppSnackBarContent> createState() => _AppSnackBarContentState();
}

class _AppSnackBarContentState extends State<AppSnackBarContent>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _pop = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 1, curve: Curves.elasticOut),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _countdown.reverse();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _countdown.dispose();
    super.dispose();
  }

  Color _toneColor(BuildContext context) => switch (widget.tone) {
    SnackTone.info => context.colors.primaryContainer,
    SnackTone.success => context.exhale.success.solid,
    SnackTone.warning => context.exhale.warning.solid,
    SnackTone.danger => context.exhale.danger.solid,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toneColor = _toneColor(context);

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - _rise.value)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * _rise.value,
            child: child,
          ),
        ),
      ),
      child: GlassSurface(
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: widget.actionLabel == null ? AppSpacing.lg : AppSpacing.sm,
          ),
          child: Row(
            children: [
              ScaleTransition(
                scale: _pop,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: toneColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: toneColor.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutterSm),
              Expanded(
                child: Text(
                  widget.message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (widget.actionLabel != null)
                TextButton(
                  onPressed: () {
                    widget.onAction!();
                    ScaffoldMessenger.of(
                      context,
                    ).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                  },
                  child: Text(widget.actionLabel!),
                ),
              const SizedBox(width: AppSpacing.sm),
              _CountdownBar(animation: _countdown, color: toneColor),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownBar extends StatelessWidget {
  const _CountdownBar({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          borderRadius: AppRadius.pill,
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: animation.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
