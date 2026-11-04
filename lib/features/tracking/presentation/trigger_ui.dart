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

  /// Each trigger keeps its hue wherever it is shown, whatever its rank.
  Color tint(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, _hue, 0.62, dark ? 0.66 : 0.46).toColor();
  }

  /// [tint] with enough contrast for small text, on a card or on the tint
  /// itself at low alpha.
  Color textTint(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, _hue, 0.62, dark ? 0.76 : 0.27).toColor();
  }

  /// Blue to magenta only, so a trigger never reads as under, at or over.
  double get _hue => 198 + 15.0 * _slot;

  /// One of 9 hues. No two triggers offered for the same habit share one.
  int get _slot => switch (this) {
    Trigger.stress => 0,
    Trigger.habit => 1,
    Trigger.boredom => 2,
    Trigger.afterMeal ||
    Trigger.notification ||
    Trigger.workout ||
    Trigger.lateNight => 3,
    Trigger.social || Trigger.bedtime => 4,
    Trigger.tired || Trigger.coffee || Trigger.avoidingTasks => 5,
    Trigger.work ||
    Trigger.watchingTv ||
    Trigger.celebrating ||
    Trigger.drinks => 6,
    Trigger.lonely || Trigger.studying => 7,
    Trigger.morning || Trigger.commute => 8,
  };
}
