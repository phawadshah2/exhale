import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
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
  final choice = await ProviderScope.containerOf(context)
      .read(nativeUiProvider)
      .showAlert(
        title: title,
        message: message,
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
    builder: (context) => Column(
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
                tint: Theme.of(context).colorScheme.primaryContainer,
                onPressed: () => Navigator.of(context).pop(selected),
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
