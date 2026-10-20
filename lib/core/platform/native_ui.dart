import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NativeAlertStyle { normal, cancel, destructive }

@immutable
class NativeAlertAction {
  const NativeAlertAction(this.label, {this.style = NativeAlertStyle.normal});

  final String label;
  final NativeAlertStyle style;
}

/// iOS system UI over a platform channel (see AppDelegate.swift).
class NativeUi {
  NativeUi([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('exhale/native_ui') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _reduceTransparency = StreamController<bool>.broadcast();

  bool get isAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  /// Shows a system alert and returns the tapped action's index, or null
  /// when native alerts are unavailable (tests, other platforms).
  Future<int?> showAlert({
    required String title,
    required List<NativeAlertAction> actions,
    String? message,
    Brightness? brightness,
    Color? tint,
  }) async {
    if (!isAvailable) return null;
    try {
      return await _channel.invokeMethod<int>('showAlert', {
        'title': title,
        'message': ?message,
        if (brightness != null) 'dark': brightness == Brightness.dark,
        if (tint != null) 'tint': tint.toARGB32(),
        'actions': [
          for (final action in actions)
            {'label': action.label, 'style': action.style.name},
        ],
      });
    } on MissingPluginException {
      return null;
    }
  }

  /// The iOS Reduce Transparency setting; false where unknown.
  Future<bool> reduceTransparency() async {
    if (!isAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('reduceTransparency') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Stream<bool> get reduceTransparencyChanges => _reduceTransparency.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'reduceTransparencyChanged') {
      _reduceTransparency.add(call.arguments as bool? ?? false);
    }
  }
}

final nativeUiProvider = Provider<NativeUi>((ref) => NativeUi());

/// Live value of the iOS Reduce Transparency setting.
final reduceTransparencyProvider = StreamProvider<bool>((ref) async* {
  final nativeUi = ref.watch(nativeUiProvider);
  yield await nativeUi.reduceTransparency();
  yield* nativeUi.reduceTransparencyChanges;
});
