import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/circle_icon_button.dart';
import 'package:exhale/core/widgets/load_failure.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/providers/edit_plan_provider.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/edit_card.dart';
import 'package:exhale/features/plan/presentation/widgets/limit_dial.dart';
import 'package:exhale/features/plan/presentation/widgets/plan_preview_card.dart';
import 'package:exhale/features/plan/presentation/widgets/price_card.dart';
import 'package:exhale/features/plan/presentation/widgets/quit_ruler.dart';
import 'package:exhale/features/plan/presentation/widgets/setup_chrome.dart';
import 'package:exhale/features/plan/presentation/widgets/your_why_sheet.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Changes a habit's daily limit, quit date and price. Changing the limit or
/// date starts a new plan today; past days keep the limits they had. Changing
/// only the price keeps the plan.
class EditPlanPage extends ConsumerWidget {
  const EditPlanPage({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(habitProvider(habitId));
    final history = ref.watch(planHistoryProvider(habitId));
    final loaded = history.value;
    if (tracked == null || loaded == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: context.pop,
                icon: Icon(AppIcons.back, color: context.colors.onSurface),
              ),
              Expanded(
                child: history.failedToLoad
                    ? LoadFailure(
                        message: "Couldn't load your plan.",
                        onRetry: () =>
                            ref.invalidate(planHistoryProvider(habitId)),
                      )
                    : const Center(child: CircularProgressIndicator.adaptive()),
              ),
            ],
          ),
        ),
      );
    }
    return _EditPlanForm(habitId: habitId, history: loaded);
  }
}

class _EditPlanForm extends ConsumerWidget {
  const _EditPlanForm({required this.habitId, required this.history});

  final int habitId;
  final PlanHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = editPlanProvider(habitId);
    final form = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final habit = ref.watch(habitProvider(habitId))!.habit;
    final settings = ref.watch(currentSettingsProvider);
    final colors = context.colors;
    final text = context.textTheme;
    final preview = form.preview;
    final yourWhy = _OutlinedAction(
      label: 'Your why',
      onPressed: () => unawaited(showYourWhySheet(context, habitId: habitId)),
    );
    final changeHabit = _OutlinedAction(
      label: 'Change habit',
      onPressed: () =>
          unawaited(context.push(AppRoutes.changeHabitFor(habitId))),
    );

    ref.listen(provider.select((s) => s.errorMessage), (_, message) {
      if (message == null) return;
      showAppSnackBar(context, message: message, tone: SnackTone.danger);
    });

    Future<void> save() async {
      final saved = await controller.save();
      if (saved && context.mounted) context.pop();
    }

    return SetupScaffold(
      footer: (bottomInset) => SetupFooter(
        label: form.planChanged || !form.priceChanged
            ? 'Shake on it again'
            : 'Save price',
        caption: form.planChanged
            ? 'Past days keep their limits. Stages start again at 1.'
            : null,
        bottomInset: bottomInset,
        isBusy: form.isSubmitting,
        onPressed: form.canSave ? save : null,
      ),
      children: [
        Row(
          spacing: AppSpacing.gutterSm,
          children: [
            CircleIconButton(
              tooltip: 'Back',
              icon: AppIcons.back,
              onPressed: context.pop,
            ),
            Expanded(child: Text('Edit plan', style: text.titleLarge)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Turn it down. Not up.', style: text.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "It does go up. I'd just rather not watch.",
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        EditCard(
          title: 'Daily limit from today',
          children: [
            Center(
              child: LimitDial(
                value: form.startLimit,
                planStartLimit: history.current.startLimit,
                unitsLabel: '${habit.unitsFor(form.startLimit)} a day',
                gapLabel: PlanCopy.paceEvery(
                  settings.dayWindow,
                  form.startLimit,
                ),
                onChanged: controller.setDailyLimit,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        EditCard(
          title: 'Quit date',
          side: _QuitDateButton(
            label: _quitLabel(form),
            onTap: () => unawaited(_pickQuitDay(context, form, controller)),
          ),
          children: [
            QuitRuler(
              today: form.today,
              selected: form.quitDay,
              spanDays: form.rulerSpanDays,
              onChanged: controller.setQuitDayFromRuler,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final preset in EditQuitPreset.values)
                  if (preset != EditQuitPreset.keepCurrent ||
                      form.canKeepCurrent)
                    _QuitChip(
                      label: preset.label,
                      selected: form.quitPreset == preset,
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        controller.selectQuitPreset(preset);
                      },
                    ),
              ],
            ),
            if (form.isSteep)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    AppIcons.stress,
                    size: 18,
                    color: context.exhale.warning.foreground,
                  ),
                  Expanded(
                    child: Text(
                      "That's more than one fewer a day. A later date may "
                      'feel easier.',
                      style: text.bodySmall?.copyWith(
                        color: context.exhale.warning.foreground,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: AppSpacing.md),
          PlanPreviewCard(plan: preview),
        ],
        if (habit.tracksCost) ...[
          const SizedBox(height: AppSpacing.md),
          PriceCard(
            habit: habit,
            form: form,
            currencySymbol: settings.currencySymbol,
            baseline: history.plans.first.startLimit,
            onPriceChanged: controller.setPriceText,
            onUnitsChanged: controller.setUnitsPerContainer,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (context.hasLargeText)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [yourWhy, changeHabit],
          )
        else
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: yourWhy),
              Expanded(child: changeHabit),
            ],
          ),
      ],
    );
  }

  /// Dec 16, with the year once it's a year or more away.
  String _quitLabel(EditPlanState form) {
    final date = AppFormat.monthDay(form.quitDay);
    return form.quitDay.daysSince(form.today) >= 365
        ? '$date, ${form.quitDay.year}'
        : date;
  }

  Future<void> _pickQuitDay(
    BuildContext context,
    EditPlanState form,
    EditPlanController controller,
  ) async {
    final picked = await showWheelPicker(
      context,
      title: 'Quit date',
      mode: CupertinoDatePickerMode.date,
      initial: form.quitDay.toLocalDate(),
      minimum: controller.earliestQuitDay.toLocalDate(),
    );
    if (picked != null) controller.setQuitDay(LogicalDay.fromDate(picked));
  }
}

class _QuitDateButton extends StatelessWidget {
  const _QuitDateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change quit date, $label',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuitChip extends StatelessWidget {
  const _QuitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: ShapeDecoration(
            color: selected ? colors.primaryContainer : null,
            shape: StadiumBorder(
              side: selected
                  ? BorderSide.none
                  : BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
