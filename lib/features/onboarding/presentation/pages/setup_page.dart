import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/number_stepper.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/onboarding/presentation/providers/setup_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/cost_card.dart';
import 'package:exhale/features/onboarding/presentation/widgets/projection_card.dart';
import 'package:exhale/features/onboarding/presentation/widgets/quit_date_card.dart';
import 'package:exhale/features/onboarding/presentation/widgets/setup_chrome.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/validation/settings_validation.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(setupFormProvider);
    final controller = ref.read(setupFormProvider.notifier);
    final today = ref.watch(todayProvider);
    final currency =
        ref.watch(settingsProvider).value?.currencySymbol ??
        AppSettings.defaultCurrencySymbol;
    final colors = context.colors;
    final text = context.textTheme;

    ref.listen(setupFormProvider.select((s) => s.errorMessage), (_, message) {
      if (message == null) return;
      showAppSnackBar(context, message: message, tone: SnackTone.danger);
    });

    Future<void> submit() async {
      final saved = await controller.submit();
      if (saved && context.mounted) context.go(AppRoutes.home);
    }

    final habit = form.habit;

    return SetupScaffold(
      footer: (bottomInset) => SetupFooter(
        label: 'Start my plan',
        bottomInset: bottomInset,
        isBusy: form.isSubmitting,
        onPressed: form.preview == null ? null : submit,
      ),
      children: [
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (context.canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: context.pop,
                    icon: Icon(AppIcons.back, color: colors.onSurface),
                  ),
                ),
              const SetupStepChip(label: 'Step 2 of 2'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Craft your gradual quitting plan', style: text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick a quit date. Your daily limit comes down evenly until then.',
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'What should we call you?',
          subtitle: 'Optional',
          child: _NameField(onChanged: controller.setName),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Your current daily amount',
          subtitle: '${_capitalize(habit.units)} on a normal day',
          trailing: const _Badge(label: 'Starting daily limit'),
          child: NumberStepper(
            value: form.startLimit,
            min: PlanValidation.minStartLimit,
            max: PlanValidation.maxStartLimit,
            onChanged: controller.setStartLimit,
            unit: habit.shortUnits,
            caption: 'per day',
            semanticLabel: 'daily amount',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StartDateCard(
          day: form.startDay,
          today: today,
          onChanged: controller.setStartDay,
        ),
        const SizedBox(height: AppSpacing.md),
        QuitDateCard(
          startDay: form.startDay,
          quitDay: form.quitDay,
          plan: form.preview,
          isSteep: form.isSteep,
          earliest: controller.earliestQuitDay,
          onPickDate: controller.setQuitDay,
          presets: [
            for (final preset in QuitPreset.values)
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
          unitPriceCents: habit.tracksCost ? form.unitPriceCents : null,
          currencySymbol: currency,
        ),
        if (habit.tracksCost) ...[
          const SizedBox(height: AppSpacing.md),
          CostCard(
            habit: habit,
            currencySymbol: currency,
            unitsPerContainer: form.unitsPerContainer,
            showPriceError: form.hasInvalidPrice,
            onPriceChanged: controller.setPriceText,
            onUnitsPerContainerChanged: controller.setUnitsPerContainer,
          ),
        ],
      ],
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.12),
        shape: StadiumBorder(
          side: BorderSide(
            color: colors.primaryContainer.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: SettingsValidation.maxNameLength,
      decoration: const InputDecoration(
        hintText: 'Your first name',
        counterText: '',
      ),
    );
  }
}

class _StartDateCard extends StatelessWidget {
  const _StartDateCard({
    required this.day,
    required this.today,
    required this.onChanged,
  });

  final LogicalDay day;
  final LogicalDay today;
  final ValueChanged<LogicalDay> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showWheelPicker(
      context,
      title: 'Start date',
      mode: CupertinoDatePickerMode.date,
      initial: day.toLocalDate(),
      minimum: today.addDays(-30).toLocalDate(),
      maximum: today.addDays(30).toLocalDate(),
    );
    if (picked != null) onChanged(LogicalDay.fromDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHighest,
                ),
                child: Icon(AppIcons.calendar, color: colors.primary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start date',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      AppFormat.relativeDate(day, today: today),
                      style: text.titleLarge,
                    ),
                  ],
                ),
              ),
              Text(
                'CHANGE',
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              Icon(AppIcons.chevronRight, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
