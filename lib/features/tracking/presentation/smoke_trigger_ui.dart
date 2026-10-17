import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    SmokeTrigger.coffee => Symbols.coffee,
    SmokeTrigger.stress => Symbols.bolt,
    SmokeTrigger.afterMeal => Symbols.restaurant,
    SmokeTrigger.social => Symbols.group,
    SmokeTrigger.boredom => Symbols.hourglass_empty,
    SmokeTrigger.habit => Symbols.repeat,
    SmokeTrigger.commute => Symbols.directions_car,
    SmokeTrigger.drinks => Symbols.local_bar,
  };
}
