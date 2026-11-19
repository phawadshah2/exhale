import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/settings/domain/subscription_tile_summary.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Subscription sheet: what the user has and what they can do with it.
Future<void> showSubscriptionSheet(BuildContext context) =>
    showAppDraggableSheet<void>(
      context,
      initialSize: 0.8,
      builder: (context, controller) =>
          _SubscriptionSheet(controller: controller),
    );

const _trialDays = 7;

class _SubscriptionSheet extends ConsumerStatefulWidget {
  const _SubscriptionSheet({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends ConsumerState<_SubscriptionSheet> {
  bool _restoring = false;

  /// An App Store sheet (manage, redeem, refund) is open.
  bool _presenting = false;

  bool get _busy =>
      _restoring || _presenting || ref.read(paywallControllerProvider).busy;

  void _storeFailed() => showAppSnackBar(
    context,
    message: PaywallCopy.cantReachStore,
    tone: SnackTone.danger,
  );

  Future<void> _call(Future<Result<Object?>> Function() action) async {
    if (_busy) return;
    setState(() => _presenting = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _presenting = false);
    if (result is FailureResult) _storeFailed();
  }

  /// Turning auto-renew off sends no store update, so ask again on return.
  void _manage() => unawaited(
    _call(ref.read(storeRepositoryProvider).manageSubscriptions).then((_) {
      if (mounted) ref.invalidate(renewingSubscriptionProvider);
    }),
  );

  void _redeem() =>
      unawaited(_call(ref.read(storeRepositoryProvider).presentCodeRedemption));

  void _refund(PlanKind plan) => unawaited(
    _call(() => ref.read(storeRepositoryProvider).requestRefund(plan)),
  );

  Future<void> _goLifetime() async {
    if (_busy) return;
    unawaited(HapticFeedback.mediumImpact());
    final controller = ref.read(paywallControllerProvider.notifier)
      ..select(PlanKind.lifetime);
    final outcome = await controller.buy();
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
        showAppSnackBar(
          context,
          message: PaywallCopy.lifetimeBought,
          tone: SnackTone.success,
        );
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

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _restoring = true);
    final outcome = await ref
        .read(paywallControllerProvider.notifier)
        .restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    switch (outcome) {
      case RestoreOutcome.restored:
        showAppSnackBar(
          context,
          message: PaywallCopy.purchasesRestored,
          tone: SnackTone.success,
        );
      case RestoreOutcome.nothingFound:
        showAppSnackBar(context, message: PaywallCopy.noPurchases);
      case RestoreOutcome.failed:
        _storeFailed();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessProvider);
    final busy =
        _restoring ||
        _presenting ||
        ref.watch(paywallControllerProvider.select((s) => s.busy));
    final autoRenews = ref.watch(autoRenewsProvider);
    final offers = ref.watch(offersProvider).value ?? const <Offer>[];
    String? price(PlanKind plan) {
      for (final offer in offers) {
        if (offer.plan == plan) return offer.displayPrice;
      }
      return null;
    }

    final today = LogicalDay.fromDate(ref.watch(clockProvider).now());

    SettingsRow action(String label, VoidCallback onTap, {String? value}) =>
        SettingsRow(label: label, value: value, onTap: onTap, enabled: !busy);
    final restore = SettingsRow(
      label: PaywallCopy.restorePurchases,
      onTap: () => unawaited(_restore()),
      enabled: !busy,
      chevron: false,
      trailing: _restoring ? const CupertinoActivityIndicator() : null,
    );
    final redeem = action(PaywallCopy.redeemCode, _redeem);
    final lifetimePrice = price(PlanKind.lifetime);
    final goLifetime = action(
      PaywallCopy.goLifetime,
      () => unawaited(_goLifetime()),
      value: lifetimePrice == null
          ? null
          : PaywallCopy.oncePrice(lifetimePrice),
    );
    final annualPrice = price(PlanKind.annual);
    final monthlyPrice = price(PlanKind.monthly);

    final content = switch (access) {
      Entitled(plan: PlanKind.lifetime) => [
        const _StatusCard(
          title: PaywallCopy.lifetimeTitle,
          line: PaywallCopy.yoursForGood,
        ),
        _RenewingNote(onCancel: _manage, enabled: !busy),
        SettingsGroup(
          iconRows: false,
          rows: [
            restore,
            redeem,
            action(PaywallCopy.requestRefund, () {
              _refund(PlanKind.lifetime);
            }),
          ],
        ),
      ],
      Entitled(:final expiresAt?, inTrial: true) => () {
        final ends = _day(expiresAt);
        final left = ends.daysSince(today);
        final date = AppFormat.monthDay(ends);
        return [
          _TrialCard(
            left: left,
            line: switch (autoRenews) {
              false => PaywallCopy.freeWeekEnds(date),
              null => PaywallCopy.freeUntil(date),
              true when annualPrice == null => PaywallCopy.planFrom(
                PaywallCopy.annual,
                date,
              ),
              true => PaywallCopy.trialStarts(date, annualPrice!),
            },
          ),
          SettingsGroup(
            header: PaywallCopy.afterFreeWeek,
            iconRows: false,
            rows: [
              action(
                PaywallCopy.payMonthlyInstead,
                _manage,
                value: monthlyPrice == null
                    ? null
                    : PaywallCopy.aMonthPrice(monthlyPrice),
              ),
              goLifetime,
            ],
          ),
          SettingsGroup(
            header: PaywallCopy.billing,
            iconRows: false,
            rows: [
              if (autoRenews == false)
                action(PaywallCopy.manageInAppStore, _manage)
              else
                action(PaywallCopy.cancelFreeWeek, _manage),
              restore,
              redeem,
            ],
          ),
          if (autoRenews != false) _FinePrint(PaywallCopy.cancelBefore(date)),
        ];
      }(),
      Entitled(:final plan, :final expiresAt) => () {
        final name = _name(plan);
        final date = expiresAt == null
            ? null
            : AppFormat.monthDay(_day(expiresAt));
        final ownPrice = price(plan);
        final yearly = plan == PlanKind.annual;
        final otherPrice = yearly ? monthlyPrice : annualPrice;
        return [
          _StatusCard(
            title: PaywallCopy.exhalePlan(name),
            line: [
              if (ownPrice != null && yearly)
                PaywallCopy.aYearPrice(ownPrice)
              else if (ownPrice != null)
                PaywallCopy.aMonthPrice(ownPrice),
              if (date != null)
                switch (autoRenews) {
                  true => PaywallCopy.renewsOn(date),
                  false => PaywallCopy.endsOn(date),
                  null => PaywallCopy.paidUntil(date),
                },
            ].join(' · '),
            active: autoRenews != false,
          ),
          SettingsGroup(
            header: PaywallCopy.changePlan,
            iconRows: false,
            rows: [
              action(
                yearly ? PaywallCopy.payMonthly : PaywallCopy.payYearly,
                _manage,
                value: otherPrice == null
                    ? null
                    : yearly
                    ? PaywallCopy.aMonthPrice(otherPrice)
                    : PaywallCopy.aYearPrice(otherPrice),
              ),
              goLifetime,
            ],
          ),
          SettingsGroup(
            header: PaywallCopy.billing,
            iconRows: false,
            rows: [
              action(PaywallCopy.manageInAppStore, _manage),
              restore,
              redeem,
              action(PaywallCopy.requestRefund, () => _refund(plan)),
            ],
          ),
          if (date != null && autoRenews != false)
            _FinePrint(PaywallCopy.cancelAnyTime(name, date)),
        ];
      }(),
      _ => () {
        final cached =
            PlanKind.values.asNameMap()[ref.watch(
              currentSettingsProvider.select((s) => s.accessPlan),
            )];
        return [
          _StatusCard(
            title: cached == null
                ? PaywallCopy.subscriptionSheetTitle
                : PaywallCopy.exhalePlan(_name(cached)),
            line: PaywallCopy.cantReachStore,
          ),
          SettingsGroup(iconRows: false, rows: [restore, redeem]),
        ];
      }(),
    };

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            PaywallCopy.subscriptionSheetTitle,
            style: context.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (i, part) in content.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          part,
        ],
      ],
    );
  }
}

LogicalDay _day(DateTime time) => LogicalDay.fromDate(time.toLocal());

String _name(PlanKind plan) => switch (plan) {
  PlanKind.annual => PaywallCopy.annual,
  PlanKind.monthly => PaywallCopy.monthlyName,
  PlanKind.lifetime => PaywallCopy.lifetime,
};

/// The plan's icon tile, name, line and, for a renewing plan, "Active".
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.line,
    this.active = false,
  });

  final String title;
  final String line;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.gutterSm,
          children: [
            const SettingsIconTile(icon: AppIcons.sparkles, filled: true),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  if (line.isNotEmpty)
                    Text(
                      line,
                      style: text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (active)
              StatusBadge(
                label: PaywallCopy.active,
                colors: context.exhale.success,
              ),
          ],
        ),
      ),
    );
  }
}

/// The free week: days left, a bar for the days used, and when Annual starts.
class _TrialCard extends StatelessWidget {
  const _TrialCard({required this.left, required this.line});

  final int left;
  final String line;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final used = ((_trialDays - left) / _trialDays).clamp(0.0, 1.0);
    final badge = trialDaysLeft(left);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(PaywallCopy.freeWeek, style: text.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutterSm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: ShapeDecoration(
                    color: context.exhale.inset,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(badge, style: text.labelMedium),
                ),
              ],
            ),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: used,
                  minHeight: 6,
                  color: colors.primary,
                  backgroundColor: context.exhale.inset,
                ),
              ),
            ),
            Text(
              line,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber note while an Annual or Monthly subscription still renews beside
/// Lifetime. Nothing when there is none, or the store could not say.
class _RenewingNote extends ConsumerWidget {
  const _RenewingNote({required this.onCancel, required this.enabled});

  final VoidCallback onCancel;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renewing = ref.watch(renewingSubscriptionProvider).value;
    if (renewing == null) return const SizedBox.shrink();
    final warning = context.exhale.warning;
    final name = _name(renewing.plan);
    final date = AppFormat.monthDay(_day(renewing.renewsAt));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: warning.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.foreground.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            PaywallCopy.stillRenews(name, date),
            style: context.textTheme.bodyMedium?.copyWith(
              color: warning.foreground,
            ),
          ),
          FilledButton(
            onPressed: enabled ? onCancel : null,
            style: FilledButton.styleFrom(
              backgroundColor: warning.solid,
              foregroundColor: warning.onSolid,
              minimumSize: const Size(0, 44),
              shape: const StadiumBorder(),
            ),
            child: Text(PaywallCopy.cancelPlan(name)),
          ),
        ],
      ),
    );
  }
}

class _FinePrint extends StatelessWidget {
  const _FinePrint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}
