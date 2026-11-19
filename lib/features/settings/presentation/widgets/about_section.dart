import 'dart:async';
import 'dart:io' show Platform;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/providers/app_info_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/settings/domain/entities/app_links.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/settings_copy.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Rate, feedback and the legal links. A row whose link is not set is hidden.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  Future<void> _feedback(BuildContext context, WidgetRef ref, String to) async {
    final launcher = ref.read(aboutLauncherProvider);
    final version = (await PackageInfo.fromPlatform()).version;
    final sent = await launcher.composeMail(
      feedbackMailUri(to: to, appVersion: version, iosVersion: _iosVersion()),
    );
    if (sent) return;
    await Clipboard.setData(ClipboardData(text: to));
    if (!context.mounted) return;
    showAppSnackBar(context, message: SettingsCopy.addressCopied);
  }

  /// "26.1" from iOS's "Version 26.1 (Build 23B85)".
  static String _iosVersion() {
    final raw = Platform.operatingSystemVersion;
    return RegExp(r'\d+(\.\d+)*').firstMatch(raw)?.group(0) ?? raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(aboutLinksProvider);
    final launcher = ref.watch(aboutLauncherProvider);
    final email = links.feedbackEmail;
    final privacy = links.privacyPolicy;
    final terms = links.terms;
    return SettingsGroup(
      header: SettingsCopy.about,
      rows: [
        SettingsRow(
          icon: AppIcons.star,
          label: SettingsCopy.rate,
          onTap: () => unawaited(launcher.requestReview()),
        ),
        if (email != null)
          SettingsRow(
            icon: AppIcons.mail,
            label: SettingsCopy.feedback,
            onTap: () => unawaited(_feedback(context, ref, email)),
          ),
        if (privacy != null)
          SettingsRow(
            icon: AppIcons.privacy,
            label: SettingsCopy.privacy,
            onTap: () => unawaited(launcher.openInApp(privacy)),
          ),
        if (terms != null)
          SettingsRow(
            icon: AppIcons.document,
            label: SettingsCopy.terms,
            onTap: () => unawaited(launcher.openInApp(terms)),
          ),
      ],
    );
  }
}

/// "Exhale 1.0.0" under the last section.
class VersionFooter extends ConsumerWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        SettingsCopy.version(version),
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
