import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/domain/services/spend_comparison.dart';
import 'package:exhale/features/paywall/presentation/paywall_content.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/paywall/presentation/widgets/legal_links.dart';
import 'package:exhale/features/paywall/presentation/widgets/paywall_steps.dart';
import 'package:exhale/features/paywall/presentation/widgets/plan_card.dart';
import 'package:exhale/features/paywall/presentation/widgets/spend_stat_card.dart';
import 'package:exhale/features/paywall/presentation/widgets/what_you_get.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The hard paywall: what the selected plan brings, the three plans, and
/// the button, which stays pinned while the rest scrolls if it must.
class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  static const pageKey = Key('paywall-page');

  /// Under this body height the steps become the icon row.
  static const double compactHeight = 540;

  /// The least space between blocks on a regular iPhone.
  static const double minGap = AppSpacing.md;

  static const plansKey = Key('paywall-plans');

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    if (ref.read(paywallControllerProvider).busy) return;
    unawaited(HapticFeedback.mediumImpact());
    final outcome = await ref.read(paywallControllerProvider.notifier).buy();
    if (!context.mounted) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
        context.go(AppRoutes.home);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        showAppSnackBar(context, message: PaywallCopy.waitingApproval);
      case null:
        showAppSnackBar(
          context,
          message: PaywallCopy.purchaseFailed,
          tone: SnackTone.danger,
        );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (ref.read(paywallControllerProvider).busy) return;
    final entitled = await ref
        .read(paywallControllerProvider.notifier)
        .restore();
    if (!context.mounted) return;
    if (entitled) {
      context.go(AppRoutes.home);
    } else {
      showAppSnackBar(context, message: PaywallCopy.noPurchases);
    }
  }

  void _select(WidgetRef ref, PlanKind plan) {
    if (ref.read(paywallControllerProvider).selected == plan) return;
    unawaited(HapticFeedback.selectionClick());
    ref.read(paywallControllerProvider.notifier).select(plan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paywallControllerProvider);
    final offersValue = ref.watch(offersProvider);
    final tracked = ref.watch(primaryHabitProvider);
    final plan = tracked == null
        ? null
        : ref.watch(planHistoryProvider(tracked.id)).value?.current;
    final currency = ref.watch(
      currentSettingsProvider.select((s) => s.currencySymbol),
    );

    final unreachable = offersValue.hasError && !offersValue.isLoading;
    final offers = offersValue.value ?? const <Offer>[];
    final loading =
        tracked == null ||
        plan == null ||
        (!unreachable && offersValue.value == null);
    final selectedOffer = offers
        .where((o) => o.plan == state.selected)
        .firstOrNull;
    final coverDays = selectedOffer == null || tracked == null || plan == null
        ? null
        : daysToCover(
            unitPriceCents: tracked.unitPriceCents,
            startLimit: plan.startLimit,
            userCurrency: currency,
            offer: selectedOffer,
          );
    final content = paywallContent(
      selected: state.selected,
      offers: offers,
      coverDays: coverDays,
      spendNoun: tracked?.habit.spendNoun ?? '',
    );
    final canBuy = !loading && !unreachable;

    return Scaffold(
      key: pageKey,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _TopBar(
              onBack: context.canPop() ? () => context.pop() : null,
              onRestore: state.busy ? null : () => _restore(context, ref),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: OnboardingStepFrame(
                button: PrimaryButton(
                  label: unreachable
                      ? PaywallCopy.continueLabel
                      : content.button,
                  isBusy: state.busy,
                  onPressed: canBuy ? () => _buy(context, ref) : null,
                ),
                below: const LegalLinksRow(),
                belowIsLinks: true,
                body: LayoutBuilder(
                  builder: (context, constraints) => _Body(
                    compact: constraints.minHeight < compactHeight,
                    content: content,
                    offers: offers,
                    selected: state.selected,
                    startLimit: plan?.startLimit,
                    loading: loading,
                    unreachable: unreachable,
                    onSelect: (plan) => _select(ref, plan),
                    onRetry: () => ref.invalidate(offersProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onRestore});

  /// Null when there is nothing under the paywall to go back to.
  final VoidCallback? onBack;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageMargin,
      AppSpacing.gutterSm,
      AppSpacing.pageMargin - 8,
      0,
    ),
    child: SizedBox(
      height: 44,
      child: Row(
        children: [
          if (onBack case final onBack?)
            RoundIconButton(
              icon: AppIcons.back,
              label: PaywallCopy.back,
              size: 44,
              onTap: onBack,
            ),
          const Spacer(),
          TextButton(
            onPressed: onRestore,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: context.colors.onSurfaceVariant,
              textStyle: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text(PaywallCopy.restore),
          ),
        ],
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.compact,
    required this.content,
    required this.offers,
    required this.selected,
    required this.startLimit,
    required this.loading,
    required this.unreachable,
    required this.onSelect,
    required this.onRetry,
  });

  final bool compact;
  final PaywallContent content;
  final List<Offer> offers;
  final PlanKind selected;
  final int? startLimit;
  final bool loading;
  final bool unreachable;
  final ValueChanged<PlanKind> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? AppSpacing.gutterSm : PaywallPage.minGap;
    final stat = content.stat;
    final limit = startLimit;
    // With no stat, the blocks spread evenly down the page so the plans stay
    // just above the button with no hole above them.
    final spread = !loading && !unreachable && stat == null;
    final middle = switch ((loading, unreachable, stat)) {
      (_, true, _) when limit != null => [
        WhatYouGet(startLimit: limit, compact: compact),
      ],
      (true, _, _) || (_, true, _) => const <Widget>[],
      (_, _, final stat?) => [
        SpendStatCard(
          days: stat.days,
          sentence: stat.sentence,
          compact: compact,
        ),
        PaywallSteps(steps: content.steps, row: compact),
      ],
      (_, _, null) => [
        PaywallSteps(steps: content.steps, row: compact),
        if (limit != null) WhatYouGet(startLimit: limit, compact: compact),
      ],
    };

    final plans = loading
        ? const <Widget>[
            SizedBox(height: 120, child: CupertinoActivityIndicator()),
          ]
        : unreachable
        ? [_Unreachable(onRetry: onRetry)]
        : [
            for (final plan in PlanKind.values)
              PlanCard(
                key: PlanCard.keyFor(plan),
                plan: plan,
                price:
                    offers
                        .where((o) => o.plan == plan)
                        .firstOrNull
                        ?.displayPrice ??
                    '',
                selected: plan == selected,
                showTrialTag: content.showTrialTag,
                onTap: () => onSelect(plan),
              ),
          ];

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        StepReveal(
          child: Semantics(
            header: true,
            child: Text(
              content.headline,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ),
      ],
    );
    final plansColumn = Column(
      key: PaywallPage.plansKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: compact ? 8 : 10,
      children: [
        for (final (i, block) in plans.indexed)
          StepReveal(index: 3 + i, child: block),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spread
          ? [
              headline,
              for (final (i, block) in middle.indexed)
                Padding(
                  padding: EdgeInsets.only(top: gap),
                  child: StepReveal(index: 1 + i, child: block),
                ),
              Padding(
                padding: EdgeInsets.only(top: gap),
                child: plansColumn,
              ),
            ]
          : [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headline,
                  for (final (i, block) in middle.indexed) ...[
                    SizedBox(height: gap),
                    StepReveal(index: 1 + i, child: block),
                  ],
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: gap + 4),
                child: plansColumn,
              ),
            ],
    );
  }
}

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          spacing: 4,
          children: [
            Text(
              PaywallCopy.unreachableTitle,
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              PaywallCopy.unreachableBody,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text(PaywallCopy.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
