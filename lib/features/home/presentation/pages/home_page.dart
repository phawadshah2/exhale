import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _logSmoke(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(logSmokeProvider)(const LogSmokeInput());
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final SmokeLog log):
        showAppSnackBar(
          context,
          message: 'Logged at ${AppFormat.time(log.loggedAt)}',
          actionLabel: 'Undo',
          onAction: () => ref.read(deleteSmokeLogProvider)(log.id),
          duration: const Duration(seconds: 2),
        );
      case FailureResult(:final failure):
        showAppSnackBar(
          context,
          message: failureMessage(failure),
          tone: SnackTone.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(todayProgressProvider).value;
    final name = ref.watch(settingsProvider).value?.userName;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = ref.watch(todayProvider);
    final text = context.textTheme;
    final colors = context.colors;

    return SafeArea(
      child: ListView(
        padding: AppSpacing.page.copyWith(top: AppSpacing.md),
        children: [
          Text(
            AppFormat.weekdayDate(today),
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            name == null
                ? AppFormat.greeting(now)
                : '${AppFormat.greeting(now)}, $name',
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: progress == null
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _TodaySummary(progress: progress),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlowButton(
            label: 'Log a smoke',
            icon: Symbols.local_fire_department,
            onPressed: progress == null ? null : () => _logSmoke(context, ref),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.progress});

  final DailyProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final status = context.exhale;
    final (message, color) = switch (progress.status) {
      LimitStatus.under => (
        '${progress.remaining} left today',
        context.colors.primary,
      ),
      LimitStatus.at => (
        'Limit reached. You can still log.',
        status.warning.foreground,
      ),
      LimitStatus.over => (
        "${progress.overBy} over today's limit",
        status.danger.foreground,
      ),
    };

    return Column(
      children: [
        Text(
          '${progress.count} / ${progress.limit}',
          key: const Key('today-count'),
          style: text.displayLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(message, style: text.headlineSmall?.copyWith(color: color)),
      ],
    );
  }
}
