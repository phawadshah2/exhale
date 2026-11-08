import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2: one chat that collects the name, habit, amount, price and day.
/// It fills from the top and scrolls under a glass bar; the dock under it
/// holds the open question's controls and the button, which stays off until
/// the plan is ready.
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
  );
  final TextEditingController _name = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _started = false;
  bool _away = false;
  double _barHeight = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _chat.addListener(_onChat);
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
    _chat
      ..removeListener(_onChat)
      ..dispose();
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _atEnd =>
      !_scroll.hasClients || _scroll.position.extentAfter < _nearEnd;

  /// Keeps the newest message in view, unless the user has scrolled back.
  void _onChat() {
    if (!_atEnd) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toEnd();
    });
  }

  void _onScroll() {
    final away = !_atEnd;
    if (away != _away) setState(() => _away = away);
  }

  void _toEnd() {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(end);
    } else {
      _scroll.animateTo(
        end,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _jump() {
    unawaited(HapticFeedback.selectionClick());
    _toEnd();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // The answer area reads the form (amount, price, currency).
    ref.watch(onboardingFormProvider);
    final colors = context.colors;
    final text = context.textTheme;
    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _Messages(
                    chat: _chat,
                    controller: _scroll,
                    top: _barHeight,
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMargin,
                AppSpacing.gutterSm,
                AppSpacing.pageMargin,
                AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothSwitcher(
                    resize: true,
                    child: KeyedSubtree(
                      key: ValueKey(_chat.ask),
                      child: _Answers(chat: _chat, name: _name),
                    ),
                  ),
                  ChevronButton(
                    label: OnboardingCopy.chatSeePlan,
                    onPressed: _chat.done
                        ? () => OnboardingScope.of(context).next()
                        : null,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OnboardingStepFrame.belowHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        OnboardingCopy.chatFinePrint,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(color: colors.outline),
                      ),
                    ),
                  ),
                ],
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
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
      children: [
        for (var i = 0; i < items.length; i++) _row(items, i),
        if (chat.typing)
          ChatRow(
            mine: false,
            topGap: items.isNotEmpty && !_isExhale(items.last),
            showAvatar: true,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: TypingBubble(),
            ),
          ),
      ],
    );
  }

  Widget _row(List<ChatItem> items, int i) {
    final item = items[i];
    final exhale = _isExhale(item);
    final previous = i > 0 ? items[i - 1] : null;
    final next = i < items.length - 1 ? items[i + 1] : null;
    final lastOfRun = next == null || _isExhale(next) != exhale;
    return ChatRow(
      key: ObjectKey(item),
      mine: !exhale,
      topGap: previous != null && _isExhale(previous) != exhale,
      showAvatar: exhale && lastOfRun && !chat.typing,
      child: switch (item) {
        ChatText() => ChatBubble(item: item),
        MoneyCard() => MoneyCardView(card: item),
      },
    );
  }
}

/// The open question's controls, one tap each.
class _Answers extends ConsumerWidget {
  const _Answers({required this.chat, required this.name});

  final OnboardingChat chat;
  final TextEditingController name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    return switch (chat.ask) {
      ChatAsk.name => _NameAnswer(chat: chat, name: name),
      ChatAsk.habit => _Grid(
        columns: 3,
        children: [
          for (final h in ChatHabit.all)
            ChatChip(
              label: chat.labelOf(h.kind),
              dashed: h.kind == HabitKind.custom,
              onTap: () => chat.pickHabit(h.kind),
            ),
        ],
      ),
      ChatAsk.amount => _Stepper(
        value: form.startLimit,
        unit: '${form.habit.units} a day',
        step: 1,
        min: 1,
        max: 80,
        onChanged: chat.setAmount,
        onSend: chat.sendAmount,
      ),
      ChatAsk.perContainer => _Stepper(
        value: form.unitsPerContainer,
        unit: '${form.habit.units} a ${chat.habit.container}',
        step: 5,
        min: 5,
        max: 200,
        onChanged: chat.setPerContainer,
        onSend: chat.sendPerContainer,
      ),
      ChatAsk.price => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Grid(
            columns: 4,
            children: [
              for (final p in chat.priceChoices)
                ChatChip(label: chat.money(p), onTap: () => chat.pickPrice(p)),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${OnboardingCopy.regionNote} · ',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              CurrencyChip(
                symbol: form.currency,
                onChanged: ref
                    .read(onboardingFormProvider.notifier)
                    .setCurrency,
              ),
              TextButton(
                onPressed: chat.skipPrice,
                child: const Text(OnboardingCopy.skipPrice),
              ),
            ],
          ),
        ],
      ),
      ChatAsk.day => ChatChip(
        label: OnboardingCopy.thatsMyDay,
        onTap: chat.sendDay,
      ),
      null => const SizedBox(width: double.infinity),
    };
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 6.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _NameAnswer extends StatelessWidget {
  const _NameAnswer({required this.chat, required this.name});

  final OnboardingChat chat;
  final TextEditingController name;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: name,
              maxLength: 24,
              autofillHints: const [AutofillHints.givenName],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.send,
              onSubmitted: chat.sendName,
              decoration: const InputDecoration(
                hintText: OnboardingCopy.nameHint,
                counterText: '',
              ),
            ),
          ),
          _SendButton(onTap: () => chat.sendName(name.text)),
        ],
      ),
      TextButton(
        onPressed: chat.skipName,
        child: const Text(OnboardingCopy.nameSkip),
      ),
    ],
  );
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () {
      unawaited(HapticFeedback.selectionClick());
      onTap();
    },
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(76, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    child: const Text(OnboardingCopy.send),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onSend,
  });

  final int value;
  final String unit;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      spacing: 6,
      children: [
        RoundIconButton(
          icon: AppIcons.remove,
          label: OnboardingCopy.fewer,
          onTap: value > min
              ? () {
                  unawaited(HapticFeedback.selectionClick());
                  onChanged((value - step).clamp(min, max));
                }
              : null,
        ),
        Expanded(
          child: Column(
            children: [
              RollingNumber(
                value: value,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                unit,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        RoundIconButton(
          icon: AppIcons.add,
          label: OnboardingCopy.more,
          onTap: value < max
              ? () {
                  unawaited(HapticFeedback.selectionClick());
                  onChanged((value + step).clamp(min, max));
                }
              : null,
        ),
        _SendButton(onTap: onSend),
      ],
    );
  }
}
