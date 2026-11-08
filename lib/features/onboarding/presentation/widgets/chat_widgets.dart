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

const double _avatar = 32;
const double _gap = 9;
const double _bubbleMax = 280;

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

/// A bubble's colours, as on the welcome chat: Exhale's in the emphasis
/// colour, the user's in the raised surface.
class ChatBubbleColors {
  factory ChatBubbleColors.of(BuildContext context, {required bool mine}) {
    final colors = context.colors;
    if (mine) {
      return ChatBubbleColors._(
        background: colors.brightness == Brightness.dark
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerHighest,
        foreground: colors.onSurface,
      );
    }
    final exhale = context.exhale;
    return ChatBubbleColors._(
      background: exhale.emphasis,
      foreground: exhale.onEmphasis,
    );
  }

  const ChatBubbleColors._({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// A row of the chat, [gap] below the one before: Exhale's side has the
/// avatar slot, the user's side is right aligned.
class ChatRow extends StatelessWidget {
  const ChatRow({
    required this.child,
    required this.mine,
    this.gap = 0,
    this.showAvatar = false,
    super.key,
  });

  /// Between lines of one side, and where the side changes.
  static const double runGap = 4;
  static const double sideGap = 12;

  final Widget child;
  final bool mine;
  final double gap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: gap),
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

/// The shape of a bubble in a run of one side's lines: later lines are
/// [continued], and every line but the run's last has [last] false.
BorderRadius chatBubbleRadius({
  required bool mine,
  bool continued = false,
  bool last = true,
}) => mine
    ? BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: Radius.circular(continued ? 6 : 20),
        bottomRight: Radius.circular(last && continued ? 20 : 6),
        bottomLeft: const Radius.circular(20),
      )
    : BorderRadius.only(
        topLeft: Radius.circular(continued ? 6 : 20),
        topRight: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
        bottomLeft: const Radius.circular(6),
      );

/// A text bubble. [onTap] makes an answer a button that reopens its
/// question.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.item,
    this.onTap,
    this.continued = false,
    this.last = true,
    super.key,
  });

  final ChatText item;
  final VoidCallback? onTap;
  final bool continued;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final mine = item.mine;
    final bubble = ChatBubbleColors.of(context, mine: mine);
    final tap = onTap;
    Widget child = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _bubbleMax),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bubble.background,
          borderRadius: chatBubbleRadius(
            mine: mine,
            continued: continued,
            last: last,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ChatMessageText(text: item.text, color: bubble.foreground),
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
          '${mine ? OnboardingCopy.chatSender : OnboardingCopy.chatName}: '
          '${item.text}',
      hint: tap == null ? null : OnboardingCopy.changeHint,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// A message's text in a bubble.
class ChatMessageText extends StatelessWidget {
  const ChatMessageText({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.bodyLarge?.copyWith(color: color, height: 1.4),
  );
}

/// Grows [child]'s height in from zero while it fades in and lifts 12 pt,
/// the first time [item] shows, so the list makes room for it smoothly; at
/// once under Reduce Motion, and never again for the same item.
class ChatEntrance extends StatefulWidget {
  const ChatEntrance({required this.item, required this.child, super.key});

  final ChatItem item;
  final Widget child;

  @override
  State<ChatEntrance> createState() => _ChatEntranceState();
}

class _ChatEntranceState extends State<ChatEntrance>
    with SingleTickerProviderStateMixin {
  static const double _rise = 12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _in = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final fresh = !widget.item.entered;
    widget.item.entered = true;
    if (fresh && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _in,
    builder: (context, child) {
      final t = _in.value;
      // One shape throughout, so the message (and a card's field) is not
      // built again when the entrance ends; it stops clipping once in.
      return ClipRect(
        clipBehavior: t < 1 ? Clip.hardEdge : Clip.none,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: t,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, _rise * (1 - t)),
              child: child,
            ),
          ),
        ),
      );
    },
    child: widget.child,
  );
}

/// "You · 10:32 PM", when the chat opened, centred above the excuses.
class ChatOpening extends StatelessWidget {
  const ChatOpening({required this.sentAt, super.key});

  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: OnboardingCopy.chatSender,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: OnboardingCopy.chatSentAt(AppFormat.time(sentAt))),
        ],
      ),
      textAlign: TextAlign.center,
      style: context.textTheme.labelSmall?.copyWith(color: colors.outline),
    );
  }
}

/// Under the last excuse: "Sent", then "Read", with the time it changed.
class ChatStatus extends StatelessWidget {
  const ChatStatus({required this.item, super.key});

  final ChatText item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, right: 6),
    // Its own node, so VoiceOver does not read it into the bubble above.
    child: Semantics(
      container: true,
      child: Text(
        OnboardingCopy.status(switch (item.delivery) {
          Delivery.sent => OnboardingCopy.sent,
          Delivery.read => OnboardingCopy.read,
        }, AppFormat.time(item.statusAt)),
        textAlign: TextAlign.right,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
    ),
  );
}

/// Exhale's three typing dots, without a bubble.
class ChatTyping extends StatelessWidget {
  const ChatTyping({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${OnboardingCopy.chatName} is typing',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TypingDots(animate: !MediaQuery.disableAnimationsOf(context)),
    ),
  );
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
    required this.continued,
    required this.children,
  });

  final Color color;
  final Color line;
  final bool continued;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _bubbleMax,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: line),
        borderRadius: chatBubbleRadius(mine: false, continued: continued),
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

/// The next 12 months: as it is on a full danger bar, with the plan on a
/// bar its share of that, and what the plan keeps.
class MoneyCardView extends StatelessWidget {
  const MoneyCardView({required this.card, this.continued = false, super.key});

  final MoneyCard card;

  /// Follows another of Exhale's lines.
  final bool continued;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final text = context.textTheme;
    final bubble = ChatBubbleColors.of(context, mine: false);
    final figures = card.figures;
    final label = text.bodySmall?.copyWith(color: bubble.foreground);
    final strong = label?.copyWith(fontWeight: FontWeight.w700);
    Widget row(String name, String value, Color? valueColor) => Row(
      spacing: 8,
      children: [
        Expanded(child: Text(name, style: label)),
        Text(value, style: strong?.copyWith(color: valueColor)),
      ],
    );
    return _CardFrame(
      color: bubble.background,
      line: colors.outlineVariant,
      continued: continued,
      children: [
        Text(
          OnboardingCopy.moneyCardTitle,
          style: text.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        row(OnboardingCopy.asItIs, figures.perYear, exhale.danger.foreground),
        _MoneyBar(share: 1, color: exhale.danger.solid),
        row(OnboardingCopy.withPlan, figures.withPlan, null),
        _MoneyBar(share: figures.planShare, color: colors.onSurfaceVariant),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: OnboardingCopy.youKeep),
              TextSpan(
                text: figures.kept,
                style: TextStyle(
                  color: exhale.success.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: text.bodyMedium?.copyWith(color: bubble.foreground),
        ),
      ],
    );
  }
}

/// An 8 pt track filled to [share] of its width.
class _MoneyBar extends StatelessWidget {
  const _MoneyBar({required this.share, required this.color});

  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 8,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: context.colors.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: share.clamp(0.02, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}
