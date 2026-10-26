import 'package:flutter/material.dart';

/// [source] cut into [dash] long pieces separated by [gap].
Path dashedPath(Path source, {double dash = 6, double gap = 4}) {
  final out = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      out.addPath(metric.extractPath(distance, distance + dash), Offset.zero);
      distance += dash + gap;
    }
  }
  return out;
}

/// Draws [text] with its top-left corner, centre or right edge at [at],
/// according to [align].
void paintLabel(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  TextAlign align = TextAlign.center,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = switch (align) {
    TextAlign.right || TextAlign.end => -painter.width,
    TextAlign.left || TextAlign.start => 0.0,
    _ => -painter.width / 2,
  };
  painter.paint(canvas, at + Offset(dx, -painter.height / 2));
}

/// A smooth curve through [points], easing flat at each point.
Path smoothPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final mid = (a.dx + b.dx) / 2;
    path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
  }
  return path;
}
