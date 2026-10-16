import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// The user's Light / Dark / System choice.
///
/// keepAlive: the root widget always watches this, but it is app-wide
/// state and should never reset just because nobody is listening for a
/// frame.
// TODO(fawad): persist the choice once local storage lands.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.dark;

  // A method (not a setter) so it can be passed as a tear-off callback.
  // ignore: use_setters_to_change_properties
  void select(ThemeMode mode) => state = mode;
}
