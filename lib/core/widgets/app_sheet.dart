import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

const double _sheetRadius = 34;
const EdgeInsets _sheetMargin = EdgeInsets.fromLTRB(10, 0, 10, 10);

/// A floating, inset glass sheet shown above everything (tab bar included).
/// It sizes to its content, up to 92% of the screen.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool showClose = true,
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
        child: AppSheetFrame(
          showClose: showClose,
          child: Flexible(child: builder(context)),
        ),
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

/// Liquid Glass panel with an iOS grabber and a glass close button;
/// [child] must be a flex child.
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({required this.child, this.showClose = true, super.key});

  final Widget child;

  /// A round glass ✕ in the top corner that dismisses the sheet.
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppGlass(
      radius: _sheetRadius,
      frosted: true,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: showClose ? 56 : 27,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 36,
                      height: 5,
                      decoration: ShapeDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.35),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  if (showClose)
                    Positioned(
                      top: 12,
                      right: 14,
                      child: GlassIconButton(
                        icon: AppIcons.close,
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
