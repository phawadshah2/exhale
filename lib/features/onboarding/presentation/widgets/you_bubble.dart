import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// A sent chat line, right aligned. In a run of lines, later ones set
/// [continued] and every one but the last sets [last] to false.
class YouBubble extends StatelessWidget {
  const YouBubble({
    required this.text,
    this.continued = false,
    this.last = true,
    super.key,
  });

  final String text;
  final bool continued;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.exhale.inset,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: Radius.circular(continued ? 6 : 20),
              bottomRight: Radius.circular(last && continued ? 20 : 6),
              bottomLeft: const Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              text,
              style: context.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
