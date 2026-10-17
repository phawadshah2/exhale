import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/number_stepper.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/onboarding/presentation/providers/setup_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/projection_card.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/validation/settings_validation.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final price = form.packPriceCents;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.page.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  const Center(child: _StepChip(label: 'Plan Setup')),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Craft your gradual quitting plan',
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Gentle reduction gives your body and mind time to adapt '
                    'without shock.',
                    style: text.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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
                    subtitle: 'Baseline consumption',
                    trailing: const _Badge(label: 'Starting daily limit'),
                    child: NumberStepper(
                      value: form.startLimit,
                      min: PlanValidation.minStartLimit,
                      max: PlanValidation.maxStartLimit,
                      onChanged: controller.setStartLimit,
                      unit: 'cigs',
                      caption: 'per day',
                      semanticLabel: 'daily amount',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    title: 'Reduce by 1 every',
                    subtitle: 'Custom tapering pace',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NumberStepper(
                          value: form.stepDays,
                          min: PlanValidation.minStepDays,
                          max: PlanValidation.maxStepDays,
                          onChanged: controller.setStepDays,
                          unit: form.stepDays == 1 ? 'day' : 'days',
                          caption: 'gradual step',
                          valueColor: colors.primary,
                          semanticLabel: 'reduction pace',
                        ),
                        const SizedBox(height: AppSpacing.gutterSm),
                        Row(
                          spacing: AppSpacing.sm,
                          children: [
                            Icon(
                              AppIcons.info,
                              size: 18,
                              color: colors.primary,
                            ),
                            Expanded(
                              child: Text(
                                '${_paceLabel(form.stepDays)}, your limit '
                                'will automatically drop by 1',
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    title: 'Target goal',
                    trailing: form.quitCompletely
                        ? Text(
                            'Zero nicotine goal',
                            style: text.labelLarge?.copyWith(
                              color: colors.primary,
                            ),
                          )
                        : null,
                    child: Column(
                      children: [
                        PillSegmentedControl<bool>(
                          selected: form.quitCompletely,
                          onChanged: (quit) => controller.setQuitCompletely(
                            quitCompletely: quit,
                          ),
                          segments: const [
                            PillSegment(
                              value: true,
                              label: '0 (Quit completely)',
                            ),
                            PillSegment(value: false, label: 'Custom limit'),
                          ],
                        ),
                        if (!form.quitCompletely) ...[
                          const SizedBox(height: AppSpacing.md),
                          NumberStepper(
                            value: form.customTarget,
                            min: 1,
                            max: form.startLimit - 1,
                            onChanged: controller.setCustomTarget,
                            unit: 'cigs',
                            caption: 'per day, final limit',
                            semanticLabel: 'target limit',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StartDateCard(
                    day: form.startDay,
                    today: today,
                    onChanged: controller.setStartDay,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PackEconomicsCard(
                    currencySymbol: currency,
                    cigarettesPerPack: form.cigarettesPerPack,
                    showPriceError: form.hasInvalidPackPrice,
                    onPriceChanged: controller.setPackPriceText,
                    onCigarettesPerPackChanged: controller.setCigarettesPerPack,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ProjectionCard(
                    plan: form.preview,
                    cigarettePriceCents: price == null
                        ? null
                        : price / form.cigarettesPerPack,
                    currencySymbol: currency,
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Padding(
                padding: AppSpacing.page.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlowButton(
                      label: 'Start my plan',
                      trailingIcon: AppIcons.forward,
                      isBusy: form.isSubmitting,
                      onPressed: form.preview == null ? null : submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        Icon(
                          AppIcons.tune,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        Flexible(
                          child: Text(
                            'You can adjust your plan anytime in Settings.',
                            textAlign: TextAlign.center,
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _paceLabel(int stepDays) =>
    stepDays == 1 ? 'Every day' : 'Every $stepDays days';

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Text(label, style: context.textTheme.labelLarge),
        ],
      ),
    );
  }
}

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
                  color: colors.surfaceContainerHigh,
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

class _PackEconomicsCard extends StatefulWidget {
  const _PackEconomicsCard({
    required this.currencySymbol,
    required this.cigarettesPerPack,
    required this.showPriceError,
    required this.onPriceChanged,
    required this.onCigarettesPerPackChanged,
  });

  final String currencySymbol;
  final int cigarettesPerPack;
  final bool showPriceError;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<int> onCigarettesPerPackChanged;

  @override
  State<_PackEconomicsCard> createState() => _PackEconomicsCardState();
}

class _PackEconomicsCardState extends State<_PackEconomicsCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                spacing: AppSpacing.gutterSm,
                children: [
                  Icon(AppIcons.savings, color: colors.primary),
                  Expanded(
                    child: Text('Pack economics', style: text.titleLarge),
                  ),
                  Icon(
                    _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                spacing: AppSpacing.gutterSm,
                children: [
                  TextField(
                    onChanged: widget.onPriceChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Price per pack',
                      prefixText: '${widget.currencySymbol} ',
                      hintText: '14.50',
                      errorText: widget.showPriceError
                          ? 'Enter a valid price'
                          : null,
                    ),
                  ),
                  NumberStepper(
                    value: widget.cigarettesPerPack,
                    min: 1,
                    max: SettingsValidation.maxCigarettesPerPack,
                    onChanged: widget.onCigarettesPerPackChanged,
                    unit: 'pcs',
                    caption: 'cigarettes per pack',
                    semanticLabel: 'cigarettes per pack',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
