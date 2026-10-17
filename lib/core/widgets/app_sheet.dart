import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

const double _sheetRadius = 34;
const EdgeInsets _sheetMargin = EdgeInsets.fromLTRB(10, 0, 10, 10);

/// A floating, inset glass sheet shown above everything (tab bar included).
/// It sizes to its content, up to 92% of the screen.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  showDragHandle: false,
  barrierColor: Colors.black.withValues(alpha: 0.32),
  builder: (context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: _sheetMargin.copyWith(
        bottom: _sheetMargin.bottom + media.viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: AppSheetFrame(child: Flexible(child: builder(context))),
      ),
    );
  },
);

/// Like [showAppSheet], but drag-resizable with a scrolling body.
Future<T?> showAppDraggableSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext, ScrollController) builder,
  double initialSize = 0.65,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  showDragHandle: false,
  barrierColor: Colors.black.withValues(alpha: 0.32),
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: initialSize,
    minChildSize: math.min(0.4, initialSize),
    maxChildSize: 0.94,
    builder: (context, controller) => Padding(
      padding: _sheetMargin,
      child: AppSheetFrame(
        child: Expanded(child: builder(context, controller)),
      ),
    ),
  ),
);

/// Rounded glass panel with an iOS grabber; [child] must be a flex child.
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    return GlassSurface(
      radius: _sheetRadius,
      blur: 30,
      color: isDark ? colors.surfaceContainer : colors.surfaceContainerLowest,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: ShapeDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.35),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
