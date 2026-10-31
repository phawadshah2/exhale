import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The pill on Details naming the shown habit. With several habits it opens a
/// sheet listing them; picking one shows it in place, with Back still going
/// Home.
class HabitSwitcher extends ConsumerWidget {
  const HabitSwitcher({required this.habitId, super.key});

  final int habitId;

  Future<void> _open(BuildContext context, List<TrackedHabit> habits) async {
    unawaited(HapticFeedback.selectionClick());
    final picked = await showAppSheet<int>(
      context,
      builder: (context) =>
          _HabitSwitcherSheet(habits: habits, shownId: habitId),
    );
    if (picked == null || picked == habitId || !context.mounted) return;
    context.replace(AppRoutes.habitFor(picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(habitProvider(habitId));
    if (tracked == null) return const SizedBox.shrink();
    final habits = ref.watch(activeHabitsProvider).value ?? const [];
    final colors = context.colors;
    final canSwitch = habits.length > 1;

    final pill = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(tracked.habit.kind.icon, size: 16, color: colors.primary),
          Flexible(
            child: Text(
              tracked.habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canSwitch)
            Icon(AppIcons.chevronDown, size: 14, color: colors.onSurface),
        ],
      ),
    );
    if (!canSwitch) return pill;

    return Tooltip(
      message: 'Switch habit',
      child: Semantics(
        button: true,
        label: 'Switch habit',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_open(context, habits)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(widthFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }
}

class _HabitSwitcherSheet extends StatelessWidget {
  const _HabitSwitcherSheet({required this.habits, required this.shownId});

  final List<TrackedHabit> habits;
  final int shownId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Switch habit', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final tracked in habits)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                Navigator.of(context).pop(tracked.id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.gutterSm,
                ),
                child: Row(
                  spacing: AppSpacing.gutterSm,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        tracked.habit.kind.icon,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tracked.habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                    ),
                    if (tracked.id == shownId)
                      Icon(AppIcons.check, size: 18, color: colors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
