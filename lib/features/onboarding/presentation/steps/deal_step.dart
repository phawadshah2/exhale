import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _Pace {
  const _Pace(this.name, this.weeks, this.blurb);

  final String name;
  final int weeks;
  final String blurb;

  int get days => weeks * 7;
}

const _paces = [
  _Pace(
    'Brisk',
    4,
    'Fast and firm. For people who’ve done this before. Allegedly.',
  ),
  _Pace('Steady', 8, 'Eight weeks. A resolution that actually sticks.'),
  _Pace('Gentle', 12, 'One fewer a week. Slow enough to actually finish.'),
];

/// Step 3: three ways to zero, the plan's rules, and the save.
class DealStep extends ConsumerStatefulWidget {
  const DealStep({super.key});

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
      _choose(_paces[_suggestedIndex(form)]);
    });
  }

  int _suggestedIndex(OnboardingFormState form) {
    final target = ReductionPlan.suggestedQuitDay(
      form.startDay,
      form.startLimit,
    ).daysSince(form.startDay);
    var best = 0;
    for (var i = 1; i < _paces.length; i++) {
      if ((_paces[i].days - target).abs() <=
          (_paces[best].days - target).abs()) {
        best = i;
      }
    }
    return best;
  }

  void _choose(_Pace pace) {
    final form = ref.read(onboardingFormProvider);
    ref
        .read(onboardingFormProvider.notifier)
        .setQuitDay(form.startDay.addDays(pace.days));
  }

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
    if (saved && mounted) context.go(AppRoutes.home);
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
              OnboardingCopy.dealEyebrow(form.startLimit),
              style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StepReveal(
            index: 1,
            child: Text(
              OnboardingCopy.dealHeadline,
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          for (final (i, pace) in _paces.indexed)
            StepReveal(
              index: 2 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PaceCard(
                  pace: pace,
                  form: form,
                  open: i == selected,
                  suggested: i == suggested,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    _choose(pace);
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

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pace,
    required this.form,
    required this.open,
    required this.suggested,
    required this.onTap,
  });

  final _Pace pace;
  final OnboardingFormState form;
  final bool open;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final text = context.textTheme;
    final quit = form.startDay.addDays(pace.days);
    final plan = ReductionPlan(
      startDay: form.startDay,
      startLimit: form.startLimit,
      quitDay: quit,
    );
    final cardColor =
        context.theme.cardTheme.color ?? colors.surfaceContainerLow;
    final name = Text(
      pace.name,
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
      OnboardingCopy.weeks(pace.weeks),
      style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
    );
    final date = Text(
      AppFormat.monthDay(quit),
      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
    // The header is read as the card's label; the rest of an open card is
    // read after it.
    final header = ExcludeSemantics(
      child: context.hasLargeText
          ? Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [name, if (suggested) badge, weeks, date],
            )
          : Row(
              spacing: 8,
              children: [
                // Takes the rest of the row, so the date sits at its end.
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      Flexible(child: name),
                      if (suggested) badge,
                      Flexible(child: weeks),
                    ],
                  ),
                ),
                date,
              ],
            ),
    );
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: open,
      onTap: onTap,
      label: [
        pace.name,
        if (suggested) OnboardingCopy.suggested.toLowerCase(),
        OnboardingCopy.weeks(pace.weeks),
        AppFormat.monthDay(quit),
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
            vertical: open ? 16 : 14,
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
                  Text(
                    pace.blurb,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  Text(
                    OnboardingCopy.dotsIntro(
                      form.startLimit,
                      form.dotUnit,
                      form.habit.units,
                    ),
                    style: text.bodySmall?.copyWith(height: 1.4),
                  ),
                  _Dots(plan: plan, form: form),
                  _Rules(plan: plan, form: form),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The days each dot goes: a dot is [OnboardingFormState.dotUnit] of the
/// starting limit, and goes on the first day the limit falls that far.
List<LogicalDay> _dropDays(ReductionPlan plan, OnboardingFormState form) {
  final unit = form.dotUnit;
  return [
    for (var k = 0; k < form.dotCount; k++)
      () {
        final target = (form.startLimit - (k + 1) * unit).clamp(0, 999);
        for (var d = 0; d <= plan.totalDays; d++) {
          final day = form.startDay.addDays(d);
          if (plan.limitOn(day) <= target) return day;
        }
        return plan.quitDay;
      }(),
  ];
}

/// One dot per unit of today's limit, each with the date it goes. In turn
/// they fade out and back, so the taper plays on a loop. Still under Reduce
/// Motion.
class _Dots extends StatefulWidget {
  const _Dots({required this.plan, required this.form});

  final ReductionPlan plan;
  final OnboardingFormState form;

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  /// 0 while the dot is on, 1 while it is gone. Dot [k] goes at 6% + 6% * k
  /// of the loop and all return at 88% to 94%.
  double _gone(double t, int k) {
    final start = (6 + 6 * k) / 100;
    if (t <= start) return 0;
    if (t < start + 0.02) return (t - start) / 0.02;
    if (t <= 0.88) return 1;
    if (t < 0.94) return 1 - (t - 0.88) / 0.06;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final days = _dropDays(widget.plan, widget.form);
    final last = days.length - 1;
    final unit = widget.form.dotUnit;
    final unitText = unit == 1 ? 'unit' : '$unit units';
    return Semantics(
      label:
          '${days.length} dots, one per $unitText of today. The first goes '
          'on ${AppFormat.monthDay(days.first)}, the '
          'last on ${AppFormat.monthDay(days[last])}, which is zero.',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = context.hasLargeText ? 3 : 6;
            final width = constraints.maxWidth / columns;
            return Wrap(
              runSpacing: 8,
              children: [
                for (var k = 0; k <= last; k++)
                  SizedBox(
                    width: width,
                    child: _dot(k, k == last, days[k], colors, text),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(
    int k,
    bool zero,
    LogicalDay day,
    ColorScheme colors,
    TextTheme text,
  ) {
    final gone = _gone(_loop.value, k);
    final ring = context.exhale.success.foreground;
    return Column(
      children: [
        Opacity(
          opacity: 1 - 0.84 * gone,
          child: Transform.scale(
            scale: 1 - 0.45 * gone,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: zero ? null : colors.onSurface,
                border: zero ? Border.all(color: ring, width: 2.5) : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormat.monthDay(day),
          maxLines: 1,
          style: text.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: zero ? ring : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.plan, required this.form});

  final ReductionPlan plan;
  final OnboardingFormState form;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final per = plan.totalDays / form.dotCount;
    final first = _dropDays(plan, form).first;
    final weekday = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][first.toLocalDate().weekday - 1];
    final rules = [
      (AppIcons.add, OnboardingCopy.ruleLog),
      (AppIcons.habit, OnboardingCopy.ruleEvery(per.round(), weekday)),
      (AppIcons.pause, OnboardingCopy.ruleHold),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            for (final (icon, line) in rules)
              Row(
                spacing: 10,
                children: [
                  Icon(icon, size: 15, color: colors.onSurface),
                  Expanded(
                    child: Text(
                      line,
                      style: context.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
