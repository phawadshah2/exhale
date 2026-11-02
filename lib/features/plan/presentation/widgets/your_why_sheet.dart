import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edits a habit's reason, saved at once and apart from the Edit plan form.
Future<void> showYourWhySheet(BuildContext context, {required int habitId}) =>
    showAppSheet<void>(context, builder: (_) => _YourWhySheet(habitId));

class _YourWhySheet extends ConsumerStatefulWidget {
  const _YourWhySheet(this.habitId);

  final int habitId;

  @override
  ConsumerState<_YourWhySheet> createState() => _YourWhySheetState();
}

class _YourWhySheetState extends ConsumerState<_YourWhySheet> {
  late final TextEditingController _reason = TextEditingController(
    text: ref.read(habitProvider(widget.habitId))?.reason,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final habit = ref.read(habitProvider(widget.habitId));
    if (habit == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(updateHabitProvider)(
      habit.copyWith(reason: () => _reason.text),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        setState(() {
          _saving = false;
          _error = failureMessage(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your why', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Optional. We'll show it on the hard days.",
            style: text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: HabitValidation.maxReasonLength,
            decoration: const InputDecoration(
              hintText: 'More energy for the people I love',
              hintMaxLines: 3,
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: text.bodySmall?.copyWith(
                color: context.exhale.danger.foreground,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Save', isBusy: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
