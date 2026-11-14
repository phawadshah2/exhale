import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_cards.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2: one chat that collects the name, habit, amount, price and day.
/// It fills from the top and scrolls under a glass bar; each question's
/// controls sit in its card. The dock holds the button, which stays off
/// until the plan is ready, and the tagline that reacts to each answer. The
/// keyboard slides over the dock, and the list ends above the keyboard.
class ChatStep extends ConsumerStatefulWidget {
  const ChatStep({super.key});

  @override
  ConsumerState<ChatStep> createState() => _ChatStepState();
}

class _ChatStepState extends ConsumerState<ChatStep>
    with AutomaticKeepAliveClientMixin {
  /// How close to the end still counts as reading the newest message.
  static const double _nearEnd = 80;

  late final OnboardingChat _chat = OnboardingChat(
    form: () => ref.read(onboardingFormProvider),
    controller: () => ref.read(onboardingFormProvider.notifier),
    reduceMotion: () => MediaQuery.disableAnimationsOf(context),
    announce: (message) {
      if (!mounted || !MediaQuery.accessibleNavigationOf(context)) return;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          Directionality.of(context),
        ),
      );
    },
  );
  final ScrollController _scroll = ScrollController();
  bool _started = false;
  bool _away = false;
  double _barHeight = 0;
  double _dockHeight = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _chat.start();
  }

  @override
  void dispose() {
    _chat.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _atEnd =>
      !_scroll.hasClients || _scroll.position.extentAfter < _nearEnd;

  /// While the user reads the newest message, the list follows the end as
  /// it moves: a message growing in, a card folding, the keyboard. It jumps
  /// each frame rather than restarting a scroll animation on each change,
  /// so the motion is the content's own. Not after scrolling back or
  /// reopening an earlier answer.
  bool _onMetrics(ScrollMetricsNotification notification) {
    if (_away || _chat.reopened != null) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      // A finger on the list wins: otherwise a growing message pulls it back
      // to the end every frame and the chat cannot be scrolled up.
      if (position.isScrollingNotifier.value) return;
      if (position.pixels != position.maxScrollExtent) {
        position.jumpTo(position.maxScrollExtent);
      }
    });
    return false;
  }

  void _onScroll() {
    final away = !_atEnd;
    if (away != _away) setState(() => _away = away);
  }

  Future<void> _toEnd() async {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(end);
    } else {
      await _scroll.animateTo(
        end,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// The list guesses the height of rows it has not built yet, so one
  /// scroll from far back can stop short of the newest message; it follows
  /// up until that message is in view.
  Future<void> _jump() async {
    unawaited(HapticFeedback.selectionClick());
    for (var i = 0; i < 4; i++) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.extentAfter == 0) return;
      await _toEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // The answer area reads the form (amount, price, currency).
    ref.watch(onboardingFormProvider);
    final colors = context.colors;
    // The page does not resize for the keyboard here, so the dock stays put
    // under it; the list ends where the keyboard begins.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: _onMetrics,
                    child: _Messages(
                      chat: _chat,
                      controller: _scroll,
                      top: _barHeight,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _HeightReporter(
                    onHeight: (height) => setState(() => _barHeight = height),
                    child: _Header(typing: _chat.typing),
                  ),
                ),
                if (_away)
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: _JumpButton(onTap: _jump),
                  ),
              ],
            ),
          ),
          SizedBox(height: math.max(0, keyboard - _dockHeight)),
          _HeightReporter(
            onHeight: (height) => setState(() => _dockHeight = height),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              // The surface runs to the bottom edge; the button sits just
              // above the safe area, as on every other step.
              child: Padding(
                padding: OnboardingStepFrame.dockPadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChevronButton(
                      label: OnboardingCopy.chatSeePlan,
                      onPressed: _chat.done
                          ? () => OnboardingScope.of(context).next()
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: OnboardingStepFrame.belowGap,
                      ),
                      child: ChatTagline(_chat.tagline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports its child's height after each layout that changes it.
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  _RenderHeightReporter createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}

/// The edge-to-edge glass app bar, under the status bar.
class _Header extends StatelessWidget {
  const _Header({required this.typing});

  final bool typing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return GlassSurface(
      radius: 0,
      blur: 20,
      opacity: 0.45,
      color: colors.brightness == Brightness.dark ? colors.surface : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 10,
          16,
          10,
        ),
        child: Row(
          spacing: 10,
          children: [
            const ChatAvatar(size: 36, online: true),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OnboardingCopy.chatName,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    typing
                        ? OnboardingCopy.chatTyping
                        : OnboardingCopy.chatIdle,
                    style: text.bodySmall?.copyWith(
                      color: typing
                          ? context.exhale.success.foreground
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round glass button that scrolls to the newest message.
class _JumpButton extends StatelessWidget {
  const _JumpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: OnboardingCopy.jumpToNewest,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassSurface(
        child: SizedBox.square(
          dimension: 44,
          child: Icon(AppIcons.chevronDown, color: context.colors.onSurface),
        ),
      ),
    ),
  );
}

/// The conversation from the top, newest at the bottom. [top] is the glass
/// bar's height, which the list starts under.
class _Messages extends StatelessWidget {
  const _Messages({
    required this.chat,
    required this.controller,
    required this.top,
  });

  final OnboardingChat chat;
  final ScrollController controller;
  final double top;

  bool _isExhale(ChatItem item) => item is! ChatText || !item.mine;

  @override
  Widget build(BuildContext context) {
    final items = chat.items;
    // Like Messages, only the newest message of the user's shows its status.
    ChatText? lastMine;
    for (final item in items) {
      if (item is ChatText && item.mine) lastMine = item;
    }
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
      children: [
        for (var i = 0; i < items.length; i++) _row(items, i, lastMine),
        if (chat.typing)
          ChatRow(
            mine: false,
            showAvatar: true,
            gap: items.isEmpty
                ? 0
                : _isExhale(items.last)
                ? ChatRow.runGap
                : ChatRow.sideGap,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: ChatTyping(),
            ),
          ),
      ],
    );
  }

  /// One item; the first carries who sent the excuses and when, and the
  /// last excuse carries their status.
  Widget _row(List<ChatItem> items, int i, ChatText? lastMine) {
    final item = items[i];
    final exhale = _isExhale(item);
    final previous = i > 0 ? items[i - 1] : null;
    final next = i < items.length - 1 ? items[i + 1] : null;
    final continued = previous != null && _isExhale(previous) == exhale;
    final lastOfRun = next == null || _isExhale(next) != exhale;
    Widget row = ChatRow(
      mine: !exhale,
      gap: previous == null
          ? 0
          : continued
          ? ChatRow.runGap
          : ChatRow.sideGap,
      // The dots take the avatar only from the run they continue.
      showAvatar: exhale && lastOfRun && !(chat.typing && next == null),
      child: switch (item) {
        ChatQuestion() => ChatQuestionView(
          question: item,
          chat: chat,
          continued: continued,
        ),
        ChatText() => ChatBubble(
          item: item,
          continued: continued,
          last: lastOfRun,
          onTap: item.answers == null || chat.typing
              ? null
              : () => chat.reopen(item),
        ),
        MoneyCard() => MoneyCardView(card: item, continued: continued),
      },
    );
    if (previous == null || item == lastMine) {
      row = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (previous == null) ...[
            ChatOpening(sentAt: item.time),
            const SizedBox(height: ChatRow.sideGap),
          ],
          row,
          if (lastMine != null && item == lastMine) ChatStatus(item: lastMine),
        ],
      );
    }
    return ChatEntrance(key: ObjectKey(item), item: item, child: row);
  }
}
