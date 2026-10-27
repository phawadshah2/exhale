import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter/widgets.dart';

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

  /// Stress and its kin read coral, work and fatigue amber, the rest teal.
  Color tint(BuildContext context) => switch (this) {
    Trigger.stress ||
    Trigger.lonely ||
    Trigger.avoidingTasks => context.exhale.danger.foreground,
    Trigger.work ||
    Trigger.tired ||
    Trigger.lateNight ||
    Trigger.bedtime => context.exhale.warning.foreground,
    _ => context.colors.primary,
  };
}
