import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

/// Every icon the app uses. SF Symbols-style Cupertino glyphs, with rounded
/// Material glyphs only where Cupertino has no equivalent.
abstract final class AppIcons {
  // Navigation
  static const IconData home = CupertinoIcons.house;
  static const IconData homeSelected = CupertinoIcons.house_fill;
  static const IconData settings = CupertinoIcons.gear;
  static const IconData settingsSelected = CupertinoIcons.gear_alt_fill;

  // Tracking
  static const IconData breath = CupertinoIcons.wind;
  static const IconData flame = CupertinoIcons.flame_fill;
  static const IconData clock = CupertinoIcons.clock;
  static const IconData trendDown = CupertinoIcons.arrow_down_right;
  static const IconData trendUp = CupertinoIcons.arrow_up_right;
  static const IconData savings = CupertinoIcons.money_dollar_circle;
  static const IconData avoided = CupertinoIcons.leaf_arrow_circlepath;
  static const IconData sparkles = CupertinoIcons.sparkles;

  // Actions
  static const IconData add = CupertinoIcons.plus;
  static const IconData remove = CupertinoIcons.minus;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData delete = CupertinoIcons.trash;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData check = CupertinoIcons.checkmark;
  static const IconData checkCircle = CupertinoIcons.checkmark_circle_fill;
  static const IconData forward = CupertinoIcons.arrow_right;
  static const IconData back = CupertinoIcons.chevron_left;
  static const IconData chevronRight = CupertinoIcons.chevron_right;
  static const IconData chevronDown = CupertinoIcons.chevron_down;
  static const IconData chevronUp = CupertinoIcons.chevron_up;

  // Misc
  static const IconData calendar = CupertinoIcons.calendar;
  static const IconData info = CupertinoIcons.info_circle;
  static const IconData tune = CupertinoIcons.slider_horizontal_3;
  static const IconData person = CupertinoIcons.person_fill;
  static const IconData palette = CupertinoIcons.paintbrush;
  static const IconData appearance = CupertinoIcons.circle_lefthalf_fill;
  static const IconData glass = CupertinoIcons.drop;

  // Habits
  static const IconData smoking = Icons.smoking_rooms_rounded;
  static const IconData vaping = CupertinoIcons.cloud;
  static const IconData alcohol = Icons.wine_bar_rounded;
  static const IconData caffeine = Icons.coffee_rounded;
  static const IconData sugar = Icons.cake_rounded;
  static const IconData customHabit = CupertinoIcons.square_pencil;

  // Triggers
  static const IconData coffee = Icons.coffee_rounded;
  static const IconData stress = CupertinoIcons.bolt_fill;
  static const IconData meal = Icons.restaurant_rounded;
  static const IconData social = CupertinoIcons.person_2;
  static const IconData boredom = CupertinoIcons.hourglass;
  static const IconData habit = CupertinoIcons.repeat;
  static const IconData commute = CupertinoIcons.car;
  static const IconData drinks = Icons.local_bar_rounded;
}
