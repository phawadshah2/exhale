import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// iOS alert with Cancel and a confirm action. Resolves true on confirm.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  // The system alert (Liquid Glass on iOS 26+); Flutter's where unavailable.
  final theme = Theme.of(context);
  final choice = await ProviderScope.containerOf(context)
      .read(nativeUiProvider)
      .showAlert(
        title: title,
        message: message,
        brightness: theme.brightness,
        tint: theme.colorScheme.primary,
        actions: [
          const NativeAlertAction('Cancel', style: NativeAlertStyle.cancel),
          NativeAlertAction(
            confirmLabel,
            style: destructive
                ? NativeAlertStyle.destructive
                : NativeAlertStyle.normal,
          ),
        ],
      );
  if (choice != null) return choice == 1;
  if (!context.mounted) return false;

  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// iOS wheel picker in a floating sheet. Resolves to the chosen value, or
/// null when dismissed.
Future<DateTime?> showWheelPicker(
  BuildContext context, {
  required String title,
  required DateTime initial,
  required CupertinoDatePickerMode mode,
  DateTime? minimum,
  DateTime? maximum,
}) {
  var selected = initial;
  return showAppSheet<DateTime>(
    context,
    showClose: false,
    builder: (context) => _WheelSheet(
      title: title,
      onDone: () => Navigator.of(context).pop(selected),
      wheel: CupertinoDatePicker(
        mode: mode,
        initialDateTime: initial,
        minimumDate: minimum,
        maximumDate: maximum,
        use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        onDateTimeChanged: (value) => selected = value,
      ),
    ),
  );
}

/// iOS wheel of [options] in a floating sheet. Resolves to the chosen
/// index, or null when dismissed.
Future<int?> showOptionWheel(
  BuildContext context, {
  required String title,
  required List<String> options,
  required int initialIndex,
  required double itemExtent,
}) {
  var selected = initialIndex;
  return showAppSheet<int>(
    context,
    showClose: false,
    builder: (context) => _WheelSheet(
      title: title,
      onDone: () => Navigator.of(context).pop(selected),
      wheel: _OptionWheel(
        options: options,
        initialIndex: initialIndex,
        itemExtent: itemExtent,
        onChanged: (index) => selected = index,
      ),
    ),
  );
}

/// Cancel, title and Done above a wheel.
class _WheelSheet extends StatelessWidget {
  const _WheelSheet({
    required this.title,
    required this.onDone,
    required this.wheel,
  });

  final String title;
  final VoidCallback onDone;
  final Widget wheel;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            GlassIconButton(
              icon: AppIcons.close,
              tooltip: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GlassIconButton(
              icon: AppIcons.check,
              tooltip: 'Done',
              tint: context.exhale.emphasis.withValues(alpha: 0.6),
              onPressed: onDone,
            ),
          ],
        ),
      ),
      SizedBox(height: 216, child: wheel),
      const SizedBox(height: AppSpacing.md),
    ],
  );
}

class _OptionWheel extends StatefulWidget {
  const _OptionWheel({
    required this.options,
    required this.initialIndex,
    required this.itemExtent,
    required this.onChanged,
  });

  final List<String> options;
  final int initialIndex;
  final double itemExtent;
  final ValueChanged<int> onChanged;

  @override
  State<_OptionWheel> createState() => _OptionWheelState();
}

class _OptionWheelState extends State<_OptionWheel> {
  late final FixedExtentScrollController _scroll = FixedExtentScrollController(
    initialItem: widget.initialIndex,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPicker(
    scrollController: _scroll,
    itemExtent: widget.itemExtent,
    onSelectedItemChanged: widget.onChanged,
    children: [
      for (final option in widget.options)
        Center(
          child: Text(option, style: Theme.of(context).textTheme.titleLarge),
        ),
    ],
  );
}
