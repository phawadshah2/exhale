import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's fonts, because the test font's square glyphs make any check
/// of how text fits meaningless.
Future<void> loadAppFonts() async {
  for (final family in ['Manrope', 'PlusJakartaSans']) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/$family-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

extension LargeText on WidgetTester {
  /// Text an overflow check cannot see: ellipsized, too tall for its box, or
  /// with a word too wide for its line. [within] limits it to one page, as
  /// pages under a pushed one are still laid out.
  List<String> clippedTexts({Finder? within}) => [
    for (final paragraph
        in within == null
            ? allRenderObjects.whereType<RenderParagraph>()
            : renderObjectList<RenderParagraph>(
                find.descendant(of: within, matching: find.byType(RichText)),
              ))
      if (paragraph.hasSize && _isClipped(paragraph))
        paragraph.text.toPlainText(),
  ];

  static bool _isClipped(RenderParagraph paragraph) {
    const slack = 1.0;
    final size = paragraph.size;
    return paragraph.didExceedMaxLines ||
        paragraph.getMinIntrinsicHeight(size.width) > size.height + slack ||
        paragraph.getMinIntrinsicWidth(double.infinity) > size.width + slack;
  }
}
