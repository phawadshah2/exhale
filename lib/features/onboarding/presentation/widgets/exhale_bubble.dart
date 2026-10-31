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
                    color: exhale.onEmphasis,
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
/// avatar. A new [text] fades the old one out, eases the bubble to the new
/// size and fades the new one in, so the bubble itself never jumps.
class ExhaleReply extends StatefulWidget {
  const ExhaleReply({required this.text, super.key});

  final String text;

  @override
  State<ExhaleReply> createState() => _ExhaleReplyState();
}

class _ExhaleReplyState extends State<ExhaleReply> {
  static const Duration _fade = Duration(milliseconds: 160);
  static const Duration _resize = Duration(milliseconds: 280);

  late String _shown = widget.text;
  bool _visible = true;

  @override
  void didUpdateWidget(ExhaleReply old) {
    super.didUpdateWidget(old);
    if (widget.text == _shown) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _shown = widget.text;
    } else {
      _visible = false;
    }
  }

  void _faded() {
    if (_visible || !mounted) return;
    setState(() {
      _shown = widget.text;
      _visible = true;
    });
  }

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
          child: AnimatedSize(
            duration: _resize,
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _visible ? _resize : _fade,
                curve: Curves.easeOut,
                onEnd: _faded,
                child: Text(
                  _shown,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: exhale.onEmphasis,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
