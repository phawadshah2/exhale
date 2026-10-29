import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2: which habit. Each pick gets a reply; Something else opens name
/// and unit fields in place.
class HabitStep extends ConsumerStatefulWidget {
  const HabitStep({super.key});

  static const int maxNameLength = 30;
  static const int maxUnitLength = 20;

  @override
  ConsumerState<HabitStep> createState() => _HabitStepState();
}

class _HabitStepState extends ConsumerState<HabitStep> {
  late final TextEditingController _name;
  late final TextEditingController _unit;

  static const double _gap = 10;

  @override
  void initState() {
    super.initState();
    final form = ref.read(onboardingFormProvider);
    _name = TextEditingController(text: form.customName);
    _unit = TextEditingController(text: form.customUnit);
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final controller = ref.read(onboardingFormProvider.notifier);
    final kind = form.habitKind;
    const presets = Habit.presets;

    return OnboardingStepFrame(
      footer: SizedBox(
        width: double.infinity,
        child: GlowButton(
          label: OnboardingCopy.continueButton,
          onPressed: form.canContinue
              ? () => OnboardingScope.of(context).next()
              : null,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingStepHeader(
            prompt: OnboardingCopy.habitPrompt,
            title: OnboardingCopy.habitTitle,
            lead: OnboardingCopy.habitLead,
          ),
          const SizedBox(height: AppSpacing.md + 4),
          for (var i = 0; i < presets.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Row(
                spacing: _gap,
                children: [
                  for (final habit in presets.skip(i).take(2))
                    Expanded(
                      child: _HabitCard(
                        icon: habit.kind.icon,
                        label: habit.name,
                        selected: kind == habit.kind,
                        onTap: () => controller.selectHabit(habit.kind),
                      ),
                    ),
                ],
              ),
            ),
          _HabitCard(
            icon: AppIcons.add,
            label: OnboardingCopy.somethingElse,
            selected: kind == HabitKind.custom,
            dashed: true,
            onTap: () => controller.selectHabit(HabitKind.custom),
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: kind == HabitKind.custom
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.gutterSm),
                    child: Column(
                      spacing: AppSpacing.gutterSm,
                      children: [
                        TextField(
                          controller: _name,
                          onChanged: controller.setCustomName,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: HabitStep.maxNameLength,
                          decoration: const InputDecoration(
                            labelText: OnboardingCopy.customNameLabel,
                            hintText: OnboardingCopy.customNameHint,
                            counterText: '',
                          ),
                        ),
                        TextField(
                          controller: _unit,
                          onChanged: controller.setCustomUnit,
                          textInputAction: TextInputAction.done,
                          maxLength: HabitStep.maxUnitLength,
                          decoration: const InputDecoration(
                            labelText: OnboardingCopy.customUnitLabel,
                            hintText: OnboardingCopy.customUnitHint,
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.md - 2),
          SmoothSwitcher(
            resize: true,
            child: ExhaleReply(
              key: ValueKey(kind),
              text: OnboardingCopy.habitReply(kind),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dashed;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.primary;
    final line = selected ? accent : colors.outlineVariant;
    final foreground = selected
        ? accent
        : dashed
        ? colors.onSurfaceVariant
        : colors.onSurface;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: dashed ? 56 : 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.14)
            : context.theme.cardTheme.color ?? colors.surfaceContainerLow,
        borderRadius: _radius,
        border: dashed
            ? null
            : Border.all(color: line, width: selected ? 1.5 : 1),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, size: 22, color: foreground),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : null,
                height: 1.2,
              ),
            ),
          ),
          if (selected) Icon(AppIcons.checkCircle, size: 16, color: accent),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: dashed
            ? CustomPaint(
                foregroundPainter: _DashedBorder(
                  color: line,
                  width: selected ? 1.5 : 1,
                ),
                child: card,
              )
            : card,
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = width / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - width, size.height - width),
      const Radius.circular(20),
    );
    canvas.drawPath(
      dashedPath(Path()..addRRect(rect)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.width != width;
}
