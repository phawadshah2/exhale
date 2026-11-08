import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/onboarding/presentation/widgets/typing_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _avatar = 28;
const double _gap = 8;
const double _bubbleMax = 284;

/// Exhale's round avatar; [visible] false keeps its space. [online] adds
/// the green dot at its lower right.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    this.visible = true,
    this.size = _avatar,
    this.online = false,
    super.key,
  });

  static const Key onlineKey = ValueKey('chat-online');

  final bool visible;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final exhale = context.exhale;
    return SizedBox.square(
      dimension: size,
      child: visible
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: exhale.emphasis,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.breath,
                      size: size * 0.55,
                      color: exhale.onEmphasis,
                    ),
                  ),
                ),
                if (online)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      key: onlineKey,
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: exhale.success.foreground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}

/// A bubble's colours. One side is ink (Exhale's in light mode, the user's
/// in dark), the other a plain card with a hairline.
class ChatBubbleColors {
  factory ChatBubbleColors.of(BuildContext context, {required bool mine}) {
    final colors = context.colors;
    final dark = colors.brightness == Brightness.dark;
    if (mine == dark) {
      return ChatBubbleColors._(
        background: colors.onSurface,
        foreground: colors.surface,
      );
    }
    return ChatBubbleColors._(
      background: dark
          ? colors.surfaceContainer
          : colors.surfaceContainerLowest,
      foreground: colors.onSurface,
      border: colors.outlineVariant,
    );
  }

  const ChatBubbleColors._({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}

/// A row of the chat: Exhale's side has the avatar slot, the user's side
/// is right aligned.
class ChatRow extends StatelessWidget {
  const ChatRow({
    required this.child,
    required this.mine,
    required this.topGap,
    this.showAvatar = false,
    super.key,
  });

  final Widget child;
  final bool mine;
  final bool topGap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topGap ? 10 : 0),
    child: mine
        ? Align(alignment: Alignment.centerRight, child: child)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: _gap,
            children: [
              ChatAvatar(visible: showAvatar),
              Flexible(child: child),
            ],
          ),
  );
}

/// The shape of a bubble on Exhale's side or the user's.
BorderRadius chatBubbleRadius({required bool mine}) => BorderRadius.only(
  topLeft: const Radius.circular(18),
  topRight: const Radius.circular(18),
  bottomLeft: Radius.circular(mine ? 18 : 6),
  bottomRight: Radius.circular(mine ? 6 : 18),
);

/// A text bubble with its time (and, for the user's, delivery ticks) set at
/// the end of the last line. [onTap] makes an answer a button that reopens
/// its question.
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.item, this.onTap, super.key});

  final ChatText item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mine = item.mine;
    final bubble = ChatBubbleColors.of(context, mine: mine);
    final time = AppFormat.time(item.time);
    final tap = onTap;
    Widget child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: mine ? 264 : _bubbleMax),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bubble.background,
          border: switch (bubble.border) {
            final line? => Border.all(color: line),
            null => null,
          },
          borderRadius: chatBubbleRadius(mine: mine),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 10, 7),
          child: ChatMessageText(item: item, color: bubble.foreground),
        ),
      ),
    );
    if (tap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          tap();
        },
        child: PressScale(child: child),
      );
    }
    return Semantics(
      button: tap != null,
      onTap: tap,
      label:
          '${mine ? 'You' : OnboardingCopy.chatName}: ${item.text}, $time'
          '${mine ? ', ${item.delivery.name}' : ''}',
      hint: tap == null ? null : OnboardingCopy.changeHint,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// A message's text with its time, and ticks on the user's, at the end of
/// the last line.
class ChatMessageText extends StatelessWidget {
  const ChatMessageText({required this.item, required this.color, super.key});

  final ChatText item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: item.text),
          // The span already scales with the text, so its own text must not
          // scale again.
          WidgetSpan(
            child: MediaQuery.withNoTextScaling(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    Text(
                      AppFormat.time(item.time),
                      style: text.labelSmall?.copyWith(
                        color: color.withValues(alpha: item.mine ? 0.65 : 0.6),
                        fontSize: 11,
                      ),
                    ),
                    if (item.mine)
                      DeliveryTicks(delivery: item.delivery, color: color),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      style: text.bodyLarge?.copyWith(color: color, height: 1.4),
    );
  }
}

/// One tick when sent, two when delivered, two in full colour when read.
class DeliveryTicks extends StatelessWidget {
  const DeliveryTicks({required this.delivery, required this.color, super.key});

  final Delivery delivery;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(17, 11),
    painter: _TickPainter(
      pair: delivery != Delivery.sent,
      color: delivery == Delivery.read ? color : color.withValues(alpha: 0.5),
    ),
  );
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.pair, required this.color});

  final bool pair;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 18, size.height / 12);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (pair) {
      path
        ..moveTo(1, 6.5)
        ..relativeLineTo(3, 3)
        ..relativeLineTo(6, -7)
        ..moveTo(7, 9.5)
        ..relativeLineTo(1, 0.5)
        ..relativeLineTo(6, -7.5);
    } else {
      path
        ..moveTo(4, 6.5)
        ..relativeLineTo(3, 3)
        ..relativeLineTo(6, -7);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.pair != pair || old.color != color;
}

/// Exhale's three typing dots in a bubble.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final bubble = ChatBubbleColors.of(context, mine: false);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${OnboardingCopy.chatName} is typing',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bubble.background,
          border: switch (bubble.border) {
            final line? => Border.all(color: line),
            null => null,
          },
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: TypingDots(
            animate: !still,
            color: bubble.foreground.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

/// The one line under "See my plan". A new [text] slides in from below as
/// the old one slides up and out; under Reduce Motion they only cross-fade.
/// VoiceOver reads each new line as a live region.
class ChatTagline extends StatelessWidget {
  const ChatTagline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = FadeTransition(opacity: animation, child: child);
            if (still) return fade;
            // The outgoing line runs this animation in reverse, so it
            // leaves upwards.
            final incoming = child.key == ValueKey(text);
            return SlideTransition(
              position: Tween(
                begin: Offset(0, incoming ? 1 : -1),
                end: Offset.zero,
              ).animate(animation),
              child: fade,
            );
          },
          child: Text(
            text,
            key: ValueKey(text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card Exhale drops into the chat, 284 wide.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.color,
    required this.line,
    required this.children,
  });

  final Color color;
  final Color line;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _bubbleMax,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: line),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: children,
        ),
      ),
    ),
  );
}

class MoneyCardView extends StatelessWidget {
  const MoneyCardView({required this.card, super.key});

  final MoneyCard card;

  @override
  Widget build(BuildContext context) {
    final success = context.exhale.success;
    final text = context.textTheme;
    final small = text.bodySmall?.copyWith(color: success.onSolid);
    final figures = card.figures;
    return _CardFrame(
      color: success.solid,
      line: success.foreground.withValues(alpha: 0.4),
      children: [
        Text(
          OnboardingCopy.moneyCardTitle,
          style: text.labelSmall?.copyWith(
            color: success.onSolid,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        // A year drops under a day when both do not fit, as at large text.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  figures.perDay,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: success.onSolid,
                  ),
                ),
                Text(OnboardingCopy.aDay, style: small),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  figures.perYear,
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: success.onSolid,
                  ),
                ),
                Text(OnboardingCopy.aYearShort, style: small),
              ],
            ),
          ],
        ),
        Text(figures.line, style: small?.copyWith(height: 1.4)),
      ],
    );
  }
}
