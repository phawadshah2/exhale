import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';

extension LimitStatusUi on LimitStatus {
  StatusColors colors(BuildContext context) => switch (this) {
    LimitStatus.under => context.exhale.success,
    LimitStatus.at => context.exhale.warning,
    LimitStatus.over => context.exhale.danger,
  };

  /// Fill for chart bars and the ring: the accent while under the limit.
  Color barColor(BuildContext context) => switch (this) {
    LimitStatus.under => context.colors.primaryContainer,
    LimitStatus.at => context.exhale.warning.solid,
    LimitStatus.over => context.exhale.danger.solid,
  };
}

extension DailyProgressUi on DailyProgress {
  String get badgeLabel => switch (status) {
    LimitStatus.under when limit == 0 => 'Smoke-free',
    LimitStatus.under => 'On track',
    LimitStatus.at => 'At limit',
    LimitStatus.over => 'Over limit',
  };
}
