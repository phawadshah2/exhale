import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// One of Exhale's chat lines, left aligned. In a run of lines only the
/// last shows the avatar; later lines set [continued] for a flat top
/// corner.
class ExhaleBubble extends StatelessWidget {
  const ExhaleBubble({
    required this.text,
    this.showAvatar = true,
    this.continued = false,
    super.key,
  });

  static const double avatarSize = 32;
  static const double _gap = 9;

  final String text;
  final bool showAvatar;
  final bool continued;

  @override
  Widget build(BuildContext context) {
    final exhale = context.exhale;
    final isDark = context.theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: avatarSize,
          child: showAvatar
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: exhale.emphasis,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.breath,
                    size: 16,
                    // On the dark accent avatar the accent glyph would vanish.
                    color: isDark
                        ? exhale.onEmphasis
                        : context.colors.primaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: _gap),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: exhale.emphasis,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(continued ? 6 : 20),
                  topRight: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                  bottomLeft: const Radius.circular(6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  text,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: exhale.onEmphasis,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Exhale's one-line reaction to an answer, right aligned without an
/// avatar.
class ExhaleReply extends StatelessWidget {
  const ExhaleReply({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final exhale = context.exhale;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: exhale.emphasis,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(6),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: exhale.onEmphasis,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
