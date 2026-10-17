import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:flutter/widgets.dart';

extension SmokeTriggerUi on SmokeTrigger {
  String get label => switch (this) {
    SmokeTrigger.coffee => 'Coffee',
    SmokeTrigger.stress => 'Stress',
    SmokeTrigger.afterMeal => 'After meal',
    SmokeTrigger.social => 'Social',
    SmokeTrigger.boredom => 'Boredom',
    SmokeTrigger.habit => 'Habit',
    SmokeTrigger.commute => 'Commute',
    SmokeTrigger.drinks => 'Drinks',
  };

  IconData get icon => switch (this) {
    SmokeTrigger.coffee => AppIcons.coffee,
    SmokeTrigger.stress => AppIcons.stress,
    SmokeTrigger.afterMeal => AppIcons.meal,
    SmokeTrigger.social => AppIcons.social,
    SmokeTrigger.boredom => AppIcons.boredom,
    SmokeTrigger.habit => AppIcons.habit,
    SmokeTrigger.commute => AppIcons.commute,
    SmokeTrigger.drinks => AppIcons.drinks,
  };
}
