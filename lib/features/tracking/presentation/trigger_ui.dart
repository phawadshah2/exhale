import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter/material.dart';

extension TriggerUi on Trigger {
  String get label => switch (this) {
    Trigger.coffee => 'Coffee',
    Trigger.stress => 'Stress',
    Trigger.afterMeal => 'After meal',
    Trigger.social => 'Social',
    Trigger.boredom => 'Boredom',
    Trigger.habit => 'Habit',
    Trigger.commute => 'Commute',
    Trigger.drinks => 'Drinks',
    Trigger.work => 'Work',
    Trigger.tired => 'Tired',
    Trigger.morning => 'Morning',
    Trigger.lateNight => 'Late night',
    Trigger.bedtime => 'Bedtime',
    Trigger.lonely => 'Lonely',
    Trigger.celebrating => 'Celebrating',
    Trigger.studying => 'Studying',
    Trigger.workout => 'Workout',
    Trigger.watchingTv => 'Watching TV',
    Trigger.notification => 'Notification',
    Trigger.avoidingTasks => 'Avoiding tasks',
  };

  IconData get icon => switch (this) {
    Trigger.coffee => AppIcons.coffee,
    Trigger.stress => AppIcons.stress,
    Trigger.afterMeal => AppIcons.meal,
    Trigger.social => AppIcons.social,
    Trigger.boredom => AppIcons.boredom,
    Trigger.habit => AppIcons.habit,
    Trigger.commute => AppIcons.commute,
    Trigger.drinks => AppIcons.drinks,
    Trigger.work => AppIcons.work,
    Trigger.tired => AppIcons.tired,
    Trigger.morning => AppIcons.morning,
    Trigger.lateNight => AppIcons.lateNight,
    Trigger.bedtime => AppIcons.bedtime,
    Trigger.lonely => AppIcons.lonely,
    Trigger.celebrating => AppIcons.celebrating,
    Trigger.studying => AppIcons.studying,
    Trigger.workout => AppIcons.workout,
    Trigger.watchingTv => AppIcons.watchingTv,
    Trigger.notification => AppIcons.notification,
    Trigger.avoidingTasks => AppIcons.avoidingTasks,
  };

  /// Each trigger keeps its own hue wherever it is shown, whatever its rank.
  Color tint(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, _hue, 0.62, dark ? 0.66 : 0.46).toColor();
  }

  double get _hue => switch (this) {
    Trigger.stress => 4,
    Trigger.coffee => 22,
    Trigger.afterMeal => 38,
    Trigger.work => 52,
    Trigger.morning => 70,
    Trigger.workout => 90,
    Trigger.habit => 112,
    Trigger.commute => 136,
    Trigger.social => 156,
    Trigger.drinks => 174,
    Trigger.boredom => 190,
    Trigger.watchingTv => 204,
    Trigger.studying => 218,
    Trigger.bedtime => 234,
    Trigger.lateNight => 250,
    Trigger.tired => 268,
    Trigger.notification => 286,
    Trigger.celebrating => 304,
    Trigger.lonely => 322,
    Trigger.avoidingTasks => 340,
  };
}
