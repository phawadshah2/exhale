import 'dart:async';
import 'dart:ui';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Access has lapsed: the user's Home, blurred and out of reach, under a
/// glass sheet that cannot be dismissed.
class LockedPage extends ConsumerWidget {
  const LockedPage({super.key});

  static const pageKey = Key('locked-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = GlassMode.of(context);
    Widget home = const HomePage();
    home = glass
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Opacity(opacity: 0.5, child: home),
          )
        : Opacity(opacity: 0.18, child: home);

    return Scaffold(
      key: pageKey,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: ExcludeSemantics(child: home)),
          // Large text can make the sheet taller than the screen; it then
          // scrolls inside the glass.
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: EdgeInsets.all(AppSpacing.sm),
              child: GlassSurface(
                radius: 30,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: _Sheet(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends ConsumerWidget {
  const _Sheet();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final busy = ref.watch(paywallControllerProvider.select((s) => s.busy));
    final progress = _progressLine(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            PaywallCopy.lockedTitle,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _endedSentence(ref.watch(accessProvider)),
          style: text.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          Text(
            progress,
            style: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: PaywallCopy.seeOffers,
          onPressed: busy
              ? null
              : () => unawaited(context.push(AppRoutes.paywall)),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: busy ? null : () => _restore(context, ref),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: colors.onSurface,
            textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          child: const Text(PaywallCopy.restorePurchases),
        ),
      ],
    );
  }

  static String _endedSentence(Access access) {
    if (access is! Lapsed) return PaywallCopy.lockedPlanEnded;
    final name = switch (access.plan) {
      PlanKind.annual => PaywallCopy.annual,
      PlanKind.monthly => PaywallCopy.monthlyName,
      PlanKind.lifetime => PaywallCopy.lifetime,
    };
    final ended = access.endedAt;
    return ended == null
        ? PaywallCopy.lockedHasEnded(name)
        : PaywallCopy.lockedEnded(
            name,
            AppFormat.monthDay(LogicalDay.fromDate(ended.toLocal())),
          );
  }

  /// "{n} days on plan · {n} {units} avoided" over "{money} saved · stage
  /// {i} of {n}"; null until the stats load.
  static String? _progressLine(WidgetRef ref) {
    final tracked = ref.watch(primaryHabitProvider);
    if (tracked == null) return null;
    final stats = ref.watch(habitStatsProvider(tracked.id)).value;
    final plan = ref.watch(planHistoryProvider(tracked.id)).value?.current;
    if (stats == null || plan == null) return null;
    final symbol = ref.watch(
      currentSettingsProvider.select((s) => s.currencySymbol),
    );
    final stage = plan.stageOn(ref.watch(todayProvider));
    final money = stats.moneySavedCents;
    final second = [
      if (money != null)
        PaywallCopy.saved(AppFormat.money(money, symbol: symbol)),
      if (stage != null) PaywallCopy.stageOf(stage.number, plan.stageCount),
    ];
    final avoided = PaywallCopy.avoided(
      AppFormat.count(stats.avoided),
      tracked.habit.unitsFor(stats.avoided),
    );
    return [
      '${PaywallCopy.daysOnPlan(stats.dayNumber)} · $avoided',
      if (second.isNotEmpty) second.join(' · '),
    ].join('\n');
  }
}
