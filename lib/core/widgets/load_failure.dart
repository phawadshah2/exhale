import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension FailedToLoad on AsyncValue<Object?> {
  /// Failed with nothing to show. A retry keeps the old error while it loads,
  /// and that counts as loading.
  bool get failedToLoad => hasError && !hasValue && !isLoading;
}

/// What a screen shows when its data cannot be read: a line and a retry.
class LoadFailure extends StatelessWidget {
  const LoadFailure({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.page,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
