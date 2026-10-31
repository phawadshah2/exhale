import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/number_stepper.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/habit/presentation/widgets/tracked_habit_guard.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/plan/presentation/providers/edit_plan_provider.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/cost_card.dart';
import 'package:exhale/features/plan/presentation/widgets/projection_card.dart';
import 'package:exhale/features/plan/presentation/widgets/quit_date_card.dart';
import 'package:exhale/features/plan/presentation/widgets/setup_chrome.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Changes a habit's daily limit, quit date, price and reason. Saving starts
/// a new plan today; past days keep the limits they had.
class EditPlanPage extends ConsumerWidget {
  const EditPlanPage({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(habitProvider(habitId));
    final history = ref.watch(planHistoryProvider(habitId)).value;
    return TrackedHabitGuard(
      habitId: habitId,
      child: tracked == null || history == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            )
          : _EditPlanForm(habitId: habitId),
    );
  }
}

const _stopTrackingNote = 'Its logs are kept. You can add it again later.';

/// Price of one unit from the form, or null without a price or cost.
double? _unitPriceCents(Habit habit, EditPlanState form) {
  final price = form.priceCents;
  if (!habit.tracksCost || price == null) return null;
  return habit.hasContainer ? price / form.unitsPerContainer : price.toDouble();
}

class _EditPlanForm extends ConsumerWidget {
  const _EditPlanForm({required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = editPlanProvider(habitId);
    final form = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final habit = ref.watch(habitProvider(habitId))!.habit;
    final currency = ref.watch(currentSettingsProvider).currencySymbol;
    final colors = context.colors;
    final text = context.textTheme;

    ref.listen(provider.select((s) => s.errorMessage), (_, message) {
      if (message == null) return;
      showAppSnackBar(context, message: message, tone: SnackTone.danger);
    });

    Future<void> save() async {
      final saved = await controller.save();
      if (saved && context.mounted) context.pop();
    }

    // Once archived, TrackedHabitGuard leaves the page.
    Future<void> stopTracking() async {
      final confirmed = await showAppConfirm(
        context,
        title: 'Stop tracking ${habit.name}?',
        message: _stopTrackingNote,
        confirmLabel: 'Stop tracking',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      final result = await ref.read(archiveHabitProvider)(habitId);
      if (!context.mounted) return;
      if (result case FailureResult(:final failure)) {
        showAppSnackBar(
          context,
          message: failureMessage(failure),
          tone: SnackTone.danger,
        );
      }
    }

    return SetupScaffold(
      footer: (bottomInset) => SetupFooter(
        label: 'Save changes',
        caption: 'Past days keep the limits they had.',
        bottomInset: bottomInset,
        isBusy: form.isSubmitting,
        onPressed: form.preview == null ? null : save,
      ),
      children: [
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: context.pop,
                  icon: Icon(AppIcons.back, color: colors.onSurface),
                ),
              ),
              Text('Edit plan', style: text.titleLarge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(habit.name, style: text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Icon(AppIcons.info, size: 18, color: colors.primary),
            Expanded(
              child: Text(
                'Changes start today. Past days keep the limits they had.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Daily limit from today',
          subtitle: '${habit.units} on a normal day',
          child: NumberStepper(
            value: form.startLimit,
            min: PlanValidation.minStartLimit,
            max: PlanValidation.maxStartLimit,
            onChanged: controller.setDailyLimit,
            unit: habit.shortUnits,
            caption: 'per day',
            semanticLabel: 'daily limit',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        QuitDateCard(
          startDay: form.today,
          quitDay: form.quitDay,
          plan: form.preview,
          isSteep: form.isSteep,
          earliest: controller.earliestQuitDay,
          onPickDate: controller.setQuitDay,
          presets: [
            for (final preset in EditQuitPreset.values)
              QuitPresetOption(
                label: preset.label,
                selected: form.quitPreset == preset,
                onSelect: () => controller.selectQuitPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ProjectionCard(
          plan: form.preview,
          habit: habit,
          unitPriceCents: _unitPriceCents(habit, form),
          currencySymbol: currency,
        ),
        if (habit.tracksCost) ...[
          const SizedBox(height: AppSpacing.md),
          CostCard(
            habit: habit,
            currencySymbol: currency,
            unitsPerContainer: form.unitsPerContainer,
            showPriceError: form.hasInvalidPrice,
            initialPriceText: form.priceText,
            onPriceChanged: controller.setPriceText,
            onUnitsPerContainerChanged: controller.setUnitsPerContainer,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Your why',
          subtitle: "Optional. We'll show it on the hard days.",
          child: TextFormField(
            initialValue: form.reason,
            onChanged: controller.setReason,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: HabitValidation.maxReasonLength,
            decoration: const InputDecoration(
              hintText: 'More energy for the people I love',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: stopTracking,
            style: TextButton.styleFrom(
              foregroundColor: context.exhale.danger.foreground,
              minimumSize: const Size(44, 44),
            ),
            child: Text('Stop tracking ${habit.name}'),
          ),
        ),
        Text(
          _stopTrackingNote,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
