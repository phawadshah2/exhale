import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

// TODO(fawad): persist the choice once local storage lands.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  // Kept as a method so it can be passed as a tear-off callback.
  // ignore: use_setters_to_change_properties
  void select(ThemeMode mode) => state = mode;
}
