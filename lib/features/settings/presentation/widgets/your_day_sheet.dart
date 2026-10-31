import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/day_window_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edits the wake and bed times, starting from the stored ones or the
/// defaults.
Future<void> showYourDaySheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _YourDaySheet());

class _YourDaySheet extends ConsumerStatefulWidget {
  const _YourDaySheet();

  @override
  ConsumerState<_YourDaySheet> createState() => _YourDaySheetState();
}

class _YourDaySheetState extends ConsumerState<_YourDaySheet> {
  late DayWindow _window =
      ref.read(currentSettingsProvider).dayWindow ??
      const DayWindow(
        wakeMinute: DayWindow.defaultWake,
        bedMinute: DayWindow.defaultBed,
      );
  bool _saving = false;

  Future<void> _save() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _saving = true);
    final window = _window;
    final result = await ref
        .read(settingsActionsProvider)
        .update(
          (settings) => settings.copyWith(
            wakeMinute: () => window.wakeMinute,
            bedMinute: () => window.bedMinute,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult():
        setState(() => _saving = false);
        showAppSnackBar(
          context,
          message: "Couldn't save your day. Try again.",
          tone: SnackTone.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your day', style: context.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          DayWindowPicker(
            window: _window,
            onChanged: (window) => setState(() => _window = window),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// The Settings row for the wake and bed times.
class YourDayTile extends ConsumerWidget {
  const YourDayTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(currentSettingsProvider).dayWindow;
    return ListTile(
      leading: Icon(AppIcons.bedtime, color: context.colors.primary),
      title: const Text('Your day'),
      subtitle: Text(
        window == null
            ? 'Not set'
            : '${AppFormat.minuteOfDay(window.wakeMinute)} – '
                  '${AppFormat.minuteOfDay(window.bedMinute)}',
      ),
      trailing: const Icon(AppIcons.chevronRight),
      onTap: () => unawaited(showYourDaySheet(context)),
    );
  }
}
