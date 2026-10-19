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
        hint: 'name your own',
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
        for (var i = 0; i < choices.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.gutterSm,
              children: [
                for (final choice in choices.skip(i).take(2))
                  Expanded(
                    child: _HabitTile(
                      choice: choice,
                      selected: form.habitKind == choice.kind,
                      onTap: () => controller.selectHabit(choice.kind),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutterSm),
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
          borderRadius: AppRadius.card,
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
            borderRadius: AppRadius.card,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? colors.primaryContainer.withValues(alpha: 0.16)
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
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          AppIcons.checkCircle,
                          size: 20,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gutterSm),
                  Text(choice.name, style: text.titleMedium),
                  Text(
                    choice.hint,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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
