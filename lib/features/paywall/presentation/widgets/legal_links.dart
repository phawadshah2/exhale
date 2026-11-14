import 'dart:async';

import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class LegalLinks {
  /// Apple's standard EULA.
  static const terms =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Set before release; the link hides while null.
  static const String? privacy = null;
}

/// "Terms" and, once it has a page, "Privacy", under the paywall's button.
class LegalLinksRow extends ConsumerWidget {
  const LegalLinksRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colors.outline,
    );
    Widget link(String label, String url) => Semantics(
      link: true,
      button: false,
      child: TextButton(
        onPressed: () => unawaited(ref.read(nativeUiProvider).openUrl(url)),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: style,
          foregroundColor: context.colors.outline,
        ),
        child: Text(label),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link(PaywallCopy.terms, LegalLinks.terms),
        if (LegalLinks.privacy case final privacy?)
          link(PaywallCopy.privacy, privacy),
      ],
    );
  }
}
