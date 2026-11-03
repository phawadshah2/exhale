import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The outlined "Edit" pill that opens Edit plan.
class EditPill extends StatelessWidget {
  const EditPill({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    void open() {
      unawaited(HapticFeedback.selectionClick());
      unawaited(context.push(AppRoutes.editPlanFor(habitId)));
    }

    return Semantics(
      button: true,
      label: 'Edit plan',
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  Icon(AppIcons.edit, size: 14, color: colors.primary),
                  Text(
                    'Edit',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
