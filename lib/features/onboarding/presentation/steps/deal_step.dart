import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_pace.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const List<OnboardingPace> _paces = OnboardingPace.all;

/// Step 3: three ways to zero, each showing its stages, an optional date of
/// the user's own, and the save.
class DealStep extends ConsumerStatefulWidget {
  const DealStep({super.key});

  /// The selected card's grid of days.
  static const Key gridKey = ValueKey('dealStageGrid');

  @override
  ConsumerState<DealStep> createState() => _DealStepState();
}

class _DealStepState extends ConsumerState<DealStep> {
  /// The replace alert is up, so another press must not open a second one.
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // An untouched plan starts on the pace nearest the suggested date.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final form = ref.read(onboardingFormProvider);
      if (form.quitPreset == null) return;
      _choose(form.startDay.addDays(_paces[_suggestedIndex(form)].days));
    });
  }

  int _suggestedIndex(OnboardingFormState form) =>
      OnboardingPace.suggestedIndex(form.startDay, form.startLimit);

  void _choose(LogicalDay quitDay) =>
      ref.read(onboardingFormProvider.notifier).setQuitDay(quitDay);

  Future<void> _pickDate() async {
    final controller = ref.read(onboardingFormProvider.notifier);
    final picked = await showWheelPicker(
      context,
      title: OnboardingCopy.quitDate,
      mode: CupertinoDatePickerMode.date,
      initial: ref.read(onboardingFormProvider).quitDay.toLocalDate(),
      minimum: controller.earliestQuitDay.toLocalDate(),
    );
    if (picked == null || !mounted) return;
    controller.setQuitDay(LogicalDay.fromDate(picked));
    final form = ref.read(onboardingFormProvider);
    final isPace = _paces.any(
      (p) => form.quitDay == form.startDay.addDays(p.days),
    );
    if (!isPace) controller.keepOwnQuitDay(form.quitDay);
  }

  Future<void> _shake() async {
    final form = ref.read(onboardingFormProvider);
    if (_asking || form.isSubmitting) return;
    unawaited(HapticFeedback.mediumImpact());
    final replaced = form.replaced;
    if (replaced != null) {
      _asking = true;
      final confirmed = await showAppConfirm(
        context,
        title: OnboardingCopy.replaceTitle(
          replaced.habit.name,
          form.habit.name,
        ),
        message: OnboardingCopy.replaceMessage(
          replaced.habit.name,
          form.habit.name,
        ),
        confirmLabel: OnboardingCopy.replaceConfirm,
        destructive: true,
      );
      _asking = false;
      if (!confirmed || !mounted) return;
    }
    final saved = await ref.read(onboardingFormProvider.notifier).submit();
    if (!saved || !mounted) return;
    // A paid user goes straight in; otherwise the paywall comes over the
    // plan, so its back returns here.
    if (form.isChangingHabit || ref.read(accessProvider) is Entitled) {
      context.go(AppRoutes.home);
    } else {
      unawaited(context.push(AppRoutes.paywall));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final colors = context.colors;
    final text = context.textTheme;
    final plan = form.preview;
    final error = form.errorMessage;
    final suggested = _suggestedIndex(form);
    final selected = _paces.indexWhere(
      (p) => form.quitDay == form.startDay.addDays(p.days),
    );
    // A date that is no pace's, as when coming back to this step, is the
    // user's own.
    final custom = form.ownQuitDay ?? (selected < 0 ? form.quitDay : null);
    final cards = [
      for (final (i, pace) in _paces.indexed)
        (
          name: pace.name,
          quit: form.startDay.addDays(pace.days),
          suggested: i == suggested,
        ),
      if (custom != null)
        (name: OnboardingCopy.customPace, quit: custom, suggested: false),
    ];

    return OnboardingStepFrame(
      button: ChevronButton(
        label: OnboardingCopy.dealGo(
          selected < 0 ? null : _paces[selected].name,
          AppFormat.monthDay(form.quitDay),
        ),
        onPressed: plan == null || form.isSubmitting ? null : _shake,
      ),
      // The fine print alone sits under the button, one line as on the
      // welcome and the chat, so the button does not move between them.
      above: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            Text(
              error,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.error),
            ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(AppIcons.calendar, size: 16),
            label: const Text(OnboardingCopy.pickOwnDate),
          ),
        ],
      ),
      below: Text(
        OnboardingCopy.dealFinePrint,
        textAlign: TextAlign.center,
        style: text.labelSmall?.copyWith(color: colors.outline),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          StepReveal(
            child: Text(
              form.isResuming
                  ? OnboardingCopy.welcomeBackEyebrow(form.userName)
                  : OnboardingCopy.dealEyebrow(form.startLimit),
              style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StepReveal(
            index: 1,
            child: Text(
              form.isResuming
                  ? OnboardingCopy.welcomeBackHeadline
                  : OnboardingCopy.dealHeadline,
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          for (final (i, card) in cards.indexed)
            StepReveal(
              index: 2 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PaceCard(
                  name: card.name,
                  quit: card.quit,
                  form: form,
                  open: form.quitDay == card.quit,
                  suggested: card.suggested,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    _choose(card.quit);
                  },
                ),
              ),
            ),
          AnimatedSize(
            duration: AppMotion.swap,
            curve: AppMotion.swapCurve,
            alignment: Alignment.topCenter,
            child: form.isSteep
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
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
                            OnboardingCopy.steepWarning,
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// The shortest and longest stage of [plan], in days.
(int, int) _stageSpan(ReductionPlan plan) {
  final lengths = [for (final stage in plan.stages) stage.lengthDays];
  return (lengths.reduce(math.min), lengths.reduce(math.max));
}

/// One way to zero. Closed, a ring of its stages; selected, the stage count
/// and a grid of its days.
class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.name,
    required this.quit,
    required this.form,
    required this.open,
    required this.suggested,
    required this.onTap,
  });

  final String name;
  final LogicalDay quit;
  final OnboardingFormState form;
  final bool open;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final text = context.textTheme;
    final plan = ReductionPlan(
      startDay: form.startDay,
      startLimit: form.startLimit,
      quitDay: quit,
    );
    final (shortest, longest) = _stageSpan(plan);
    final stagesLine = OnboardingCopy.stagesLine(
      plan.stageCount,
      shortest,
      longest,
    );
    final length = OnboardingCopy.planLength(plan.totalDays);
    final cardColor =
        context.theme.cardTheme.color ?? colors.surfaceContainerLow;
    final title = Text(
      name,
      overflow: TextOverflow.ellipsis,
      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: exhale.emphasis,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          OnboardingCopy.suggested,
          style: text.labelSmall?.copyWith(
            color: exhale.onEmphasis,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
    final weeks = Text(
      length,
      style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
    );
    final date = Text(
      AppFormat.monthDay(quit),
      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
    final ring = _StageRing(
      plan: plan,
      label: OnboardingCopy.stageSpan(shortest, longest),
    );
    // The header is read as the card's label; the rest of an open card is
    // read after it.
    final header = ExcludeSemantics(
      child: context.hasLargeText
          ? Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!open) ring,
                title,
                if (suggested) badge,
                weeks,
                date,
              ],
            )
          : Row(
              spacing: 8,
              children: [
                if (!open) ring,
                // Takes the rest of the row, so the date sits at its end.
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      Flexible(child: title),
                      if (suggested) badge,
                      Flexible(child: weeks),
                    ],
                  ),
                ),
                date,
              ],
            ),
    );
    final muted = text.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
      height: 1.35,
    );
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: open,
      onTap: onTap,
      label: [
        name,
        if (suggested) OnboardingCopy.suggested.toLowerCase(),
        length,
        AppFormat.monthDay(quit),
        stagesLine,
      ].join(', '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.swap,
          curve: AppMotion.swapCurve,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: open ? 16 : 10,
          ),
          decoration: BoxDecoration(
            color: open ? exhale.inset : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: open ? exhale.emphasis : colors.outlineVariant,
              width: open ? 1.5 : 1,
            ),
          ),
          child: AnimatedSize(
            duration: AppMotion.swap,
            curve: AppMotion.swapCurve,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                header,
                if (open) ...[
                  ExcludeSemantics(child: Text(stagesLine, style: muted)),
                  _StageGrid(key: DealStep.gridKey, plan: plan),
                  Text(
                    OnboardingCopy.gridNote(_StageGrid.squareDays(plan)),
                    style: muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A ring of [plan]'s stages: each segment as long as its stage, darker for
/// a higher limit, with [label] (how long a stage lasts) inside.
class _StageRing extends StatelessWidget {
  const _StageRing({required this.plan, required this.label});

  final ReductionPlan plan;
  final String label;

  static const double size = 38;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _StageRingPainter(plan: plan, color: context.exhale.emphasis),
      child: Center(
        child: MediaQuery.withNoTextScaling(
          child: Text(
            label,
            maxLines: 1,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    ),
  );
}

class _StageRingPainter extends CustomPainter {
  _StageRingPainter({required this.plan, required this.color});

  final ReductionPlan plan;
  final Color color;

  static const double _stroke = 4;
  static const double _gap = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final gap = _gap / radius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    var start = -math.pi / 2;
    for (final stage in plan.stages) {
      final sweep = stage.lengthDays / plan.totalDays * 2 * math.pi;
      paint.color = color.withValues(
        alpha: 0.3 + 0.7 * stage.limit / plan.startLimit,
      );
      canvas.drawArc(
        rect,
        start,
        math.max(sweep - gap, sweep / 2),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_StageRingPainter old) =>
      old.plan.totalDays != plan.totalDays ||
      old.plan.startLimit != plan.startLimit ||
      old.color != color;
}

/// [plan]'s limits as squares, the quit day last as a check: one a day
/// while that fits [_maxColumns] × [_maxRows], else one per week (or per N
/// weeks). It uses the fewest columns that fit in [_maxRows] rows, so a
/// shorter plan gets bigger squares. VoiceOver reads it as
/// one line.
class _StageGrid extends StatelessWidget {
  const _StageGrid({required this.plan, super.key});

  final ReductionPlan plan;

  static const int _maxColumns = 14;
  static const int _minColumns = 7;
  static const int _maxRows = 7;
  static const double _gap = 2;

  /// Days each square stands for.
  static int squareDays(ReductionPlan plan) {
    const cells = _maxColumns * _maxRows;
    if (plan.totalDays + 1 <= cells) return 1;
    return ((plan.totalDays + 1) / cells / 7).ceil() * 7;
  }

  /// Columns for [count] squares. Never fewer than [_minColumns], so a
  /// plan of under four weeks takes fewer rows instead of huge squares.
  static int columns(int count) =>
      (count / _maxRows).ceil().clamp(_minColumns, _maxColumns);

  @override
  Widget build(BuildContext context) {
    final step = squareDays(plan);
    final squares = (plan.totalDays / step).ceil();
    final limits = [
      for (var i = 0; i < squares; i++)
        plan.limitOn(plan.startDay.addDays(i * step)),
    ];
    final count = squares + 1;
    final columnCount = columns(count);
    return Semantics(
      label: OnboardingCopy.gridSummary(
        plan.totalDays,
        plan.startLimit,
        AppFormat.monthDay(plan.quitDay),
      ),
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side =
                (constraints.maxWidth - _gap * (columnCount - 1)) / columnCount;
            final rows = (count / columnCount).ceil();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: _gap,
              children: [
                for (var r = 0; r < rows; r++)
                  Row(
                    spacing: _gap,
                    children: [
                      for (
                        var i = r * columnCount;
                        i < math.min(count, (r + 1) * columnCount);
                        i++
                      )
                        _square(
                          context,
                          side: side,
                          limit: i < squares ? limits[i] : null,
                          first: i == 0,
                          drop:
                              i > 0 &&
                              i < squares &&
                              limits[i] != limits[i - 1],
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A null [limit] is the quit day.
  Widget _square(
    BuildContext context, {
    required double side,
    required int? limit,
    required bool first,
    required bool drop,
  }) {
    final colors = context.colors;
    final exhale = context.exhale;
    final strength = limit == null
        ? 0.0
        : 0.12 + 0.78 * limit / plan.startLimit;
    final fontSize = (side * 0.34).clamp(7.0, 14.0);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: limit == null
            ? exhale.success.soft
            : exhale.emphasis.withValues(alpha: strength),
        borderRadius: BorderRadius.circular(side < 24 ? 3 : 5),
      ),
      foregroundDecoration: first
          ? BoxDecoration(
              border: Border.all(color: colors.onSurface, width: 1.5),
              borderRadius: BorderRadius.circular(side < 24 ? 3 : 5),
            )
          : null,
      child: limit == null
          ? Icon(
              AppIcons.check,
              size: fontSize + 2,
              color: exhale.success.foreground,
            )
          : Text(
              '$limit',
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
                fontWeight: drop ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: strength > 0.55 ? exhale.onEmphasis : colors.onSurface,
              ),
            ),
    );
  }
}
