import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:flutter/widgets.dart';

extension HabitIcon on HabitKind {
  IconData get icon => switch (this) {
    HabitKind.smoking => AppIcons.smoking,
    HabitKind.vaping => AppIcons.vaping,
    HabitKind.alcohol => AppIcons.alcohol,
    HabitKind.caffeine => AppIcons.caffeine,
    HabitKind.sugar => AppIcons.sugar,
    HabitKind.custom => AppIcons.customHabit,
  };
}
