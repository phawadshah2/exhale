import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_picker.dart';
import 'package:flutter/material.dart';

/// Asks what triggered a smoke. Returns the choice, or null when skipped.
Future<SmokeTrigger?> showTriggerSheet(BuildContext context) =>
    showAppSheet<SmokeTrigger>(
      context,
      builder: (context) => const _TriggerSheet(),
    );

class _TriggerSheet extends StatefulWidget {
  const _TriggerSheet();

  @override
  State<_TriggerSheet> createState() => _TriggerSheetState();
}

class _TriggerSheetState extends State<_TriggerSheet> {
  SmokeTrigger? _selected;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What triggered this smoke?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Understanding patterns helps identify cravings (optional).',
            style: text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TriggerPicker(
            selected: _selected,
            onChanged: (trigger) => setState(() => _selected = trigger),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
            child: const Text('Save trigger'),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
