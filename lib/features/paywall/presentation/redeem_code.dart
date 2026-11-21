import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens Apple's code redemption sheet. Access follows from the store's
/// change, so the paywall or locked screen leaves on its own.
Future<void> redeemCode(BuildContext context, WidgetRef ref) async {
  if (ref.read(paywallControllerProvider).busy) return;
  final result = await ref
      .read(storeRepositoryProvider)
      .presentCodeRedemption();
  if (!context.mounted || result is! FailureResult) return;
  showAppSnackBar(
    context,
    message: PaywallCopy.cantReachStore,
    tone: SnackTone.danger,
  );
}
