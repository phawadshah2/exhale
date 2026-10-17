import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS alert with Cancel and a confirm action. Resolves true on confirm.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
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
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: mode,
            initialDateTime: initial,
            minimumDate: minimum,
            maximumDate: maximum,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            onDateTimeChanged: (value) => selected = value,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}
