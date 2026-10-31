import 'dart:async';

import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/amount_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/cost_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/day_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/habit_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moves between onboarding steps, so steps never hold the page controller.
class OnboardingScope extends InheritedWidget {
  const OnboardingScope({
    required this.next,
    required this.back,
    required super.child,
    super.key,
  });

  final VoidCallback next;
  final VoidCallback back;

  static OnboardingScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingScope>()!;

  @override
  bool updateShouldNotify(OnboardingScope oldWidget) => false;
}

/// The onboarding steps, one page each. Forward only through a step's
/// button; the back chevron and a right swipe go back one step.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pages = PageController();
  late OnboardingStep _current = _steps.first;

  static const Duration _turn = Duration(milliseconds: 380);
  static const double _backFlingVelocity = 300;

  List<OnboardingStep> get _steps => ref.read(onboardingFormProvider).steps;

  /// Adding a habit was opened from the app, so the first step can go back.
  bool get _canLeave => ref.read(onboardingFormProvider).isAddingHabit;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    FocusScope.of(context).unfocus();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: _turn,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _next() {
    final steps = _steps;
    final index = steps.indexOf(_current);
    if (index < steps.length - 1) _goTo(index + 1);
  }

  void _back() {
    final index = _steps.indexOf(_current);
    if (index <= 0 && !_canLeave) return;
    unawaited(HapticFeedback.selectionClick());
    if (index <= 0) {
      Navigator.of(context).pop();
    } else {
      _goTo(index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cost is added or removed only when the habit changes.
    ref
      ..watch(onboardingFormProvider.select((s) => s.total))
      ..listen(onboardingFormProvider.select((s) => s.total), (_, _) {
        // Keep the current step by identity once the pages are rebuilt.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pages.hasClients) return;
          final index = _steps.indexOf(_current);
          if (_pages.page?.round() != index) _pages.jumpToPage(index);
        });
      });
    final steps = _steps;
    final index = steps.indexOf(_current);

    return OnboardingScope(
      next: _next,
      back: _back,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              OnboardingStepper(
                index: index,
                total: steps.length,
                onBack: index > 0 || _canLeave ? _back : null,
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > _backFlingVelocity) {
                      _back();
                    }
                  },
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _current = steps[i]),
                    children: [
                      for (final step in steps)
                        KeyedSubtree(
                          key: ValueKey(step),
                          child: switch (step) {
                            OnboardingStep.welcome => const WelcomeStep(),
                            OnboardingStep.habit => const HabitStep(),
                            OnboardingStep.amount => const AmountStep(),
                            OnboardingStep.cost => const CostStep(),
                            OnboardingStep.day => const DayStep(),
                            OnboardingStep.deal => const DealStep(),
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A step's scrollable body above its pinned [button]. [body] gets at least
/// the visible height, so a `Column` with `spaceBetween` puts its last
/// child at the bottom. [below] (a link or fine print) sits in a slot of
/// [belowHeight] under the button, so the button is at the same height on
/// every step.
class OnboardingStepFrame extends StatelessWidget {
  const OnboardingStepFrame({
    required this.body,
    required this.button,
    this.below,
    this.onTapBody,
    super.key,
  });

  static const double belowHeight = 44;

  final Widget body;
  final Widget button;
  final Widget? below;
  final VoidCallback? onTapBody;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapBody,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: body,
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMargin,
          AppSpacing.gutterSm,
          AppSpacing.pageMargin,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: double.infinity, child: button),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: belowHeight),
              child: Align(alignment: Alignment.topCenter, child: below),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Exhale's prompt bubble above a step's title and optional lead.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    required this.prompt,
    required this.title,
    this.lead,
    super.key,
  });

  final String prompt;
  final String title;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        StepReveal(child: ExhaleBubble(text: prompt)),
        const SizedBox(height: AppSpacing.md + 2),
        StepReveal(
          index: 1,
          child: SmoothSwitcher(
            resize: true,
            child: SizedBox(
              key: ValueKey(title),
              width: double.infinity,
              child: Text(
                title,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),
        if (lead != null) ...[
          const SizedBox(height: AppSpacing.sm),
          StepReveal(
            index: 2,
            child: Text(
              lead!,
              style: text.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
