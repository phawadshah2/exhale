import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every box shadow drawn under [of].
List<BoxShadow> shadowsUnder(WidgetTester tester, Finder of) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)),
  ))
    ...switch (box.decoration) {
      final ShapeDecoration d => d.shadows ?? const <BoxShadow>[],
      final BoxDecoration d => d.boxShadow ?? const <BoxShadow>[],
      _ => const <BoxShadow>[],
    },
];

/// Fails when any paint in a canvas's calls is blurred.
PaintPattern get paintsWithoutBlur => paints
  ..everything((method, arguments) {
    for (final argument in arguments) {
      if (argument is Paint && argument.maskFilter != null) {
        // An "everything" step reports only a thrown String.
        // ignore: only_throw_errors
        throw 'found a blurred $method';
      }
    }
    return true;
  });
