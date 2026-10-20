import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/onboarding/presentation/providers/setup_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/setup_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 1: what the user is cutting down, and why.
class HabitPickerPage extends ConsumerWidget {
  const HabitPickerPage({super.key});

  static const int maxReasonLength = 80;
  static const int _columns = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(setupFormProvider);
    final controller = ref.read(setupFormProvider.notifier);
    final colors = context.colors;
    final text = context.textTheme;

    final choices = [
      for (final habit in Habit.presets)
        _HabitChoice(kind: habit.kind, name: habit.name, hint: habit.units),
      const _HabitChoice(
        kind: HabitKind.custom,
        name: 'Custom',
        hint: 'your own',
      ),
    ];

    return SetupScaffold(
      footer: (bottomInset) => SetupFooter(
        label: 'Continue',
        caption: 'You can change this later in Settings.',
        bottomInset: bottomInset,
        onPressed: form.canContinue
            ? () => context.push(AppRoutes.setupPlan)
            : null,
      ),
      children: [
        const SizedBox(
          height: 40,
          child: Center(child: SetupStepChip(label: 'Step 1 of 2')),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('What are you cutting down?', style: text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick one habit. Your plan, wording and savings follow it.',
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < choices.length; i += _columns) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                for (var j = i; j < i + _columns; j++)
                  Expanded(
                    child: j < choices.length
                        ? _HabitTile(
                            choice: choices[j],
                            selected: form.habitKind == choices[j].kind,
                            onTap: () =>
                                controller.selectHabit(choices[j].kind),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: form.habitKind == HabitKind.custom
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _CustomHabitCard(
                    onNameChanged: controller.setCustomName,
                    onUnitChanged: controller.setCustomUnit,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.xs),
        SectionCard(
          title: 'Why are you doing this?',
          subtitle: "Optional. We'll show it on the hard days.",
          child: TextField(
            onChanged: controller.setReason,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: maxReasonLength,
            decoration: const InputDecoration(
              hintText: 'More energy for the people I love',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitChoice {
  const _HabitChoice({
    required this.kind,
    required this.name,
    required this.hint,
  });

  final HabitKind kind;
  final String name;
  final String hint;
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _HabitChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: choice.name,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.08)
              : colors.surfaceContainerLow,
          borderRadius: AppRadius.inner,
          border: Border.all(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.7)
                : colors.outlineVariant.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.inner,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onTap();
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? colors.primaryContainer.withValues(
                                    alpha: 0.16,
                                  )
                                : colors.surfaceContainerHigh,
                          ),
                          child: Icon(
                            choice.kind.icon,
                            size: 22,
                            color: selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        choice.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(height: 1.15),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          choice.hint,
                          maxLines: 1,
                          style: text.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      AppIcons.checkCircle,
                      size: 14,
                      color: colors.primary,
                    ),
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

class _CustomHabitCard extends StatelessWidget {
  const _CustomHabitCard({
    required this.onNameChanged,
    required this.onUnitChanged,
  });

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Your habit',
      subtitle: 'Name it, and say what one log counts.',
      child: Column(
        spacing: AppSpacing.gutterSm,
        children: [
          TextField(
            onChanged: onNameChanged,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Habit',
              hintText: 'Energy drinks',
              counterText: '',
            ),
          ),
          TextField(
            onChanged: onUnitChanged,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'One log is a…',
              hintText: 'can',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
