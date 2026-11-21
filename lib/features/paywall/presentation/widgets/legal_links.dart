import 'dart:async';

import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/settings/domain/entities/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Terms" and, once it has a page, "Privacy", under the paywall's button,
/// then "Redeem a code" when [onRedeem] is set. It wraps at large text.
class LegalLinksRow extends ConsumerWidget {
  const LegalLinksRow({super.key, this.onRedeem, this.redeemEnabled = true});

  final VoidCallback? onRedeem;
  final bool redeemEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colors.outline,
    );
    Widget button(String label, VoidCallback? onPressed) => TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: style,
        foregroundColor: context.colors.outline,
      ),
      child: Text(label),
    );
    Widget link(String label, String url) => Semantics(
      link: true,
      button: false,
      child: button(
        label,
        () => unawaited(ref.read(nativeUiProvider).openUrl(url)),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        link(PaywallCopy.terms, AppLinks.terms),
        if (AppLinks.privacy case final privacy?)
          link(PaywallCopy.privacy, privacy),
        if (onRedeem case final onRedeem?)
          button(PaywallCopy.redeemCode, redeemEnabled ? onRedeem : null),
      ],
    );
  }
}
