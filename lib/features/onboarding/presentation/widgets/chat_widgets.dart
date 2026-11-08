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

/// Exhale's round avatar; [visible] false keeps its space.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({this.visible = true, this.size = _avatar, super.key});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final exhale = context.exhale;
    return SizedBox.square(
      dimension: size,
      child: visible
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: exhale.emphasis,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.breath,
                size: size * 0.55,
                color: exhale.onEmphasis,
              ),
            )
          : null,
    );
  }
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

/// A text bubble with its time (and, for the user's, delivery ticks) set at
/// the end of the last line.
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.item, super.key});

  final ChatText item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final mine = item.mine;
    final background = mine ? exhale.emphasis : colors.surfaceContainerHigh;
    final foreground = mine ? exhale.onEmphasis : colors.onSurface;
    final faint = foreground.withValues(alpha: mine ? 0.65 : 0.6);
    final text = context.textTheme;
    final time = AppFormat.time(item.time);
    return Semantics(
      label:
          '${mine ? 'You' : OnboardingCopy.chatName}: ${item.text}, $time'
          '${mine ? ', ${item.delivery.name}' : ''}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mine ? 264 : _bubbleMax),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: mine ? null : Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 7),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: item.text),
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 3,
                        children: [
                          Text(
                            time,
                            style: text.labelSmall?.copyWith(
                              color: faint,
                              fontSize: 11,
                            ),
                          ),
                          if (mine)
                            DeliveryTicks(
                              delivery: item.delivery,
                              color: foreground,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              style: text.bodyLarge?.copyWith(color: foreground, height: 1.4),
            ),
          ),
        ),
      ),
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
    final colors = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${OnboardingCopy.chatName} is typing',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: TypingDots(animate: !still, color: colors.onSurfaceVariant),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

/// A pill answer chip, 48 pt tall.
class ChatChip extends StatelessWidget {
  const ChatChip({
    required this.label,
    required this.onTap,
    this.dashed = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  /// "Something else" gets a quieter border.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final pick = SelectionColors.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: PressScale(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: pick.idleFill,
              shape: StadiumBorder(
                side: BorderSide(
                  color: dashed ? colors.outline : pick.idleLine,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
