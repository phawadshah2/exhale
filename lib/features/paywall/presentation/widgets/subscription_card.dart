import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings' "Subscription": the plan and what is known of its date,
/// Manage (not for Lifetime) and Restore.
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (ref.read(paywallControllerProvider).busy) return;
    final entitled = await ref
        .read(paywallControllerProvider.notifier)
        .restore();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: entitled
          ? PaywallCopy.purchasesRestored
          : PaywallCopy.noPurchases,
      tone: entitled ? SnackTone.success : SnackTone.info,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider);
    final busy = ref.watch(paywallControllerProvider.select((s) => s.busy));
    final entitled = access is Entitled ? access : null;

    return SectionCard(
      title: PaywallCopy.subscriptionTitle,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          if (entitled != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_name(entitled.plan)),
              trailing: Text(
                _dateLine(entitled),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          if (entitled?.plan != PlanKind.lifetime)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(PaywallCopy.manageSubscription),
              trailing: const Icon(AppIcons.chevronRight),
              onTap: () => unawaited(
                ref.read(storeRepositoryProvider).manageSubscriptions(),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(PaywallCopy.restorePurchases),
            enabled: !busy,
            onTap: () => _restore(context, ref),
          ),
        ],
      ),
    );
  }

  static String _name(PlanKind plan) => switch (plan) {
    PlanKind.annual => PaywallCopy.annual,
    PlanKind.monthly => PaywallCopy.monthlyName,
    PlanKind.lifetime => PaywallCopy.lifetime,
  };

  static String _dateLine(Entitled access) {
    final expires = access.expiresAt;
    if (expires == null) return PaywallCopy.yoursForGood;
    final date = AppFormat.monthDay(LogicalDay.fromDate(expires.toLocal()));
    return access.inTrial
        ? PaywallCopy.freeUntil(date)
        : PaywallCopy.paidUntil(date);
  }
}
