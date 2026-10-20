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
    SmokeTrigger.work => 'Work',
    SmokeTrigger.tired => 'Tired',
    SmokeTrigger.morning => 'Morning',
    SmokeTrigger.lateNight => 'Late night',
    SmokeTrigger.bedtime => 'Bedtime',
    SmokeTrigger.lonely => 'Lonely',
    SmokeTrigger.celebrating => 'Celebrating',
    SmokeTrigger.studying => 'Studying',
    SmokeTrigger.workout => 'Workout',
    SmokeTrigger.watchingTv => 'Watching TV',
    SmokeTrigger.notification => 'Notification',
    SmokeTrigger.avoidingTasks => 'Avoiding tasks',
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
    SmokeTrigger.work => AppIcons.work,
    SmokeTrigger.tired => AppIcons.tired,
    SmokeTrigger.morning => AppIcons.morning,
    SmokeTrigger.lateNight => AppIcons.lateNight,
    SmokeTrigger.bedtime => AppIcons.bedtime,
    SmokeTrigger.lonely => AppIcons.lonely,
    SmokeTrigger.celebrating => AppIcons.celebrating,
    SmokeTrigger.studying => AppIcons.studying,
    SmokeTrigger.workout => AppIcons.workout,
    SmokeTrigger.watchingTv => AppIcons.watchingTv,
    SmokeTrigger.notification => AppIcons.notification,
    SmokeTrigger.avoidingTasks => AppIcons.avoidingTasks,
  };
}
