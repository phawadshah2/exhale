import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:flutter/widgets.dart';

extension HabitIcon on HabitKind {
  IconData get icon => switch (this) {
    HabitKind.smoking => AppIcons.smoking,
    HabitKind.vaping => AppIcons.vaping,
    HabitKind.nicotinePouches => AppIcons.nicotinePouches,
    HabitKind.alcohol => AppIcons.alcohol,
    HabitKind.caffeine => AppIcons.caffeine,
    HabitKind.energyDrinks => AppIcons.energyDrinks,
    HabitKind.junkFood => AppIcons.junkFood,
    HabitKind.socialMedia => AppIcons.socialMedia,
    HabitKind.custom => AppIcons.customHabit,
  };
}
