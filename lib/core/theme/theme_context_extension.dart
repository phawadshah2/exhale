import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  /// Status colours and emphasis. Always present: AppTheme registers it.
  ExhaleColors get exhale => theme.extension<ExhaleColors>()!;
}
