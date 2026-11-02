import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the type of each haptic played during the test.
List<String> recordHaptics(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  final played = <String>[];
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      played.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return played;
}
