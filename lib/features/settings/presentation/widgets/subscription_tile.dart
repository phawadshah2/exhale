import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/settings/domain/subscription_tile_summary.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/subscription_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The subscription tile; it opens the Subscription sheet.
class SubscriptionTile extends ConsumerWidget {
  const SubscriptionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsTile(
    icon: AppIcons.sparkles,
    summary: subscriptionTileSummary(
      access: ref.watch(accessProvider),
      cachedPlan: ref.watch(
        currentSettingsProvider.select((s) => s.accessPlan),
      ),
      now: ref.watch(clockProvider).now(),
    ),
    onTap: () => unawaited(showSubscriptionSheet(context)),
  );
}
