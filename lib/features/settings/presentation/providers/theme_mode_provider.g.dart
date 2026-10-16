// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's Light / Dark / System choice.
///
/// keepAlive: the root widget always watches this, but it is app-wide
/// state and should never reset just because nobody is listening for a
/// frame.
// TODO(fawad): persist the choice once local storage lands.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// The user's Light / Dark / System choice.
///
/// keepAlive: the root widget always watches this, but it is app-wide
/// state and should never reset just because nobody is listening for a
/// frame.
// TODO(fawad): persist the choice once local storage lands.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// The user's Light / Dark / System choice.
  ///
  /// keepAlive: the root widget always watches this, but it is app-wide
  /// state and should never reset just because nobody is listening for a
  /// frame.
  // TODO(fawad): persist the choice once local storage lands.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'787e9b3e7fa4b42790f5c35bbc9ca99a927a7d43';

/// The user's Light / Dark / System choice.
///
/// keepAlive: the root widget always watches this, but it is app-wide
/// state and should never reset just because nobody is listening for a
/// frame.
// TODO(fawad): persist the choice once local storage lands.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
