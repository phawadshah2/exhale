import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/habit_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An Exhale question: its text with its controls under it while open,
/// folded back to a plain bubble once answered.
class ChatQuestionView extends StatelessWidget {
  const ChatQuestionView({
    required this.question,
    required this.chat,
    this.continued = false,
    super.key,
  });

  final ChatQuestion question;
  final OnboardingChat chat;

  /// Follows another of Exhale's lines.
  final bool continued;

  @override
  Widget build(BuildContext context) {
    final child = !question.open
        ? ChatBubble(item: question, continued: continued)
        : ChatCardFrame(
            question: question,
            continued: continued,
            label: switch (question.ask) {
              ChatAsk.name => OnboardingCopy.cardName,
              ChatAsk.habit => OnboardingCopy.cardHabit,
              ChatAsk.amount => OnboardingCopy.cardAmount,
              ChatAsk.price => OnboardingCopy.cardPrice(chat.habit.container),
              ChatAsk.perContainer => OnboardingCopy.cardPerPod(
                chat.form().habit.units,
                chat.habit.container ?? '',
              ),
              ChatAsk.day => OnboardingCopy.cardDay,
            },
            width: question.ask == ChatAsk.habit ? 300 : 284,
            child: _controls(),
          );
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: child,
    );
  }

  Widget _controls() => switch (question.ask) {
    ChatAsk.name => NameCard(chat: chat),
    ChatAsk.habit => HabitCard(chat: chat),
    ChatAsk.amount => AmountCard(chat: chat),
    ChatAsk.price => PriceCard(chat: chat),
    ChatAsk.perContainer => PerPodCard(chat: chat),
    ChatAsk.day => DayQuestionCard(chat: chat),
  };
}

/// Colours for controls inside a card, from Exhale's bubble: its text
/// colour as ink on the emphasis colour.
class ChatCardColors {
  factory ChatCardColors.of(BuildContext context) {
    final bubble = ChatBubbleColors.of(context, mine: false);
    final ink = bubble.foreground;
    return ChatCardColors._(
      ink: ink,
      card: bubble.background,
      fill: ink.withValues(alpha: 0.06),
      line: ink.withValues(alpha: 0.2),
      muted: ink.withValues(alpha: 0.7),
    );
  }

  const ChatCardColors._({
    required this.ink,
    required this.card,
    required this.fill,
    required this.line,
    required this.muted,
  });

  /// Text and the solid buttons' fill.
  final Color ink;

  /// The card itself, and text on a solid button.
  final Color card;
  final Color fill;
  final Color line;
  final Color muted;
}

/// A question bubble with its controls under the text, one VoiceOver group
/// named [label].
class ChatCardFrame extends StatelessWidget {
  const ChatCardFrame({
    required this.question,
    required this.label,
    required this.width,
    required this.child,
    this.continued = false,
    super.key,
  });

  final ChatQuestion question;
  final String label;
  final double width;
  final Widget child;
  final bool continued;

  @override
  Widget build(BuildContext context) {
    final bubble = ChatBubbleColors.of(context, mine: false);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubble.background,
            borderRadius: chatBubbleRadius(mine: false, continued: continued),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                ChatMessageText(text: question.text, color: bubble.foreground),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The first name, or "I'd rather not say".
class NameCard extends ConsumerStatefulWidget {
  const NameCard({required this.chat, super.key});

  final OnboardingChat chat;

  @override
  ConsumerState<NameCard> createState() => _NameCardState();
}

class _NameCardState extends ConsumerState<NameCard> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(onboardingFormProvider).userName,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      _FieldRow(
        controller: _name,
        hint: OnboardingCopy.nameHint,
        sendLabel: OnboardingCopy.sendName,
        maxLength: 24,
        autofill: AutofillHints.givenName,
        onSend: widget.chat.sendName,
      ),
      _CardPill(label: OnboardingCopy.nameSkip, onTap: widget.chat.skipName),
    ],
  );
}

/// Every habit in three rows of small pills, or under Other, a field for
/// the user's own.
class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({required this.chat, super.key});

  final OnboardingChat chat;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  late final TextEditingController _custom;
  bool _other = false;

  @override
  void initState() {
    super.initState();
    _custom = TextEditingController(
      text: ref.read(onboardingFormProvider).customName,
    );
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    if (_other) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _FieldRow(
            controller: _custom,
            hint: OnboardingCopy.customNameHint,
            label: OnboardingCopy.customHabitAsk,
            sendLabel: OnboardingCopy.sendHabit,
            maxLength: HabitStep.maxNameLength,
            onSend: (name) =>
                chat.pickHabit(HabitKind.custom, customName: name),
          ),
          _CardPill(
            label: OnboardingCopy.backToList,
            onTap: () => setState(() => _other = false),
          ),
        ],
      );
    }
    const habits = ChatHabit.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row = 0; row < habits.length; row += 3)
          Wrap(
            spacing: 6,
            children: [
              for (final habit in habits.skip(row).take(3))
                _HabitPill(
                  label: chat.labelOf(habit.kind),
                  dashed: habit.kind == HabitKind.custom,
                  onTap: habit.kind == HabitKind.custom
                      ? () => setState(() => _other = true)
                      : () => chat.pickHabit(habit.kind),
                ),
            ],
          ),
      ],
    );
  }
}

/// How many a day: a stepper well and "That's about right".
class AmountCard extends ConsumerWidget {
  const AmountCard({required this.chat, super.key});

  final OnboardingChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        CardStepper(
          value: form.startLimit,
          unit: OnboardingCopy.perDay(form.habit.units),
          min: PlanValidation.minStartLimit,
          max: PlanValidation.maxStartLimit,
          onChanged: chat.setAmount,
        ),
        CardButton(label: OnboardingCopy.aboutRight, onTap: chat.sendAmount),
      ],
    );
  }
}

/// The price: scaled chips and Other, the currency, or "I'd rather not
/// know".
class PriceCard extends ConsumerStatefulWidget {
  const PriceCard({required this.chat, super.key});

  final OnboardingChat chat;

  @override
  ConsumerState<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends ConsumerState<PriceCard> {
  late final TextEditingController _price;
  bool _other = false;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: ref.read(onboardingFormProvider).priceText,
    );
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (!widget.chat.sendPriceText(text)) setState(() => _invalid = true);
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final form = ref.watch(onboardingFormProvider);
    final card = ChatCardColors.of(context);
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        if (_other) ...[
          _FieldRow(
            controller: _price,
            hint: OnboardingCopy.priceHint,
            label: OnboardingCopy.cardPrice(chat.habit.container),
            sendLabel: OnboardingCopy.sendPrice,
            maxLength: 9,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSend: _send,
          ),
          if (_invalid)
            Text(
              OnboardingCopy.invalidPrice,
              style: text.bodySmall?.copyWith(color: card.ink),
            ),
          _CardPill(
            label: OnboardingCopy.backToList,
            onTap: () => setState(() {
              _other = false;
              _invalid = false;
            }),
          ),
        ] else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final price in chat.priceChoices)
                _CardPill(
                  label: chat.money(price),
                  strong: true,
                  onTap: () => chat.pickPrice(price),
                ),
              _CardPill(
                label: OnboardingCopy.other,
                onTap: () => setState(() => _other = true),
              ),
            ],
          ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${form.currency} · ',
              style: text.bodySmall?.copyWith(color: card.muted),
            ),
            Semantics(
              button: true,
              label: OnboardingCopy.currency,
              value: form.currency,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(
                  CurrencyChip.pickCurrency(
                    context,
                    symbol: form.currency,
                    onChanged: ref
                        .read(onboardingFormProvider.notifier)
                        .setCurrency,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      OnboardingCopy.change,
                      style: text.bodySmall?.copyWith(
                        color: card.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _CardPill(label: OnboardingCopy.skipPrice, onTap: chat.skipPrice),
      ],
    );
  }
}

/// How many one container holds, by fives, and how long one lasts.
class PerPodCard extends ConsumerWidget {
  const PerPodCard({required this.chat, super.key});

  final OnboardingChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    final container = chat.habit.container ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        CardStepper(
          value: form.unitsPerContainer,
          unit: '${form.habit.units} a $container',
          step: 5,
          min: 5,
          max: HabitValidation.maxUnitsPerContainer,
          fewerLabel: OnboardingCopy.fiveFewer,
          moreLabel: OnboardingCopy.fiveMore,
          onChanged: chat.setPerContainer,
        ),
        Text(
          OnboardingCopy.perPodCaption(
            per: form.unitsPerContainer,
            amount: form.startLimit,
            container: container,
          ),
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: ChatCardColors.of(context).muted,
          ),
        ),
        CardButton(
          label: OnboardingCopy.aboutRight,
          onTap: chat.sendPerContainer,
        ),
      ],
    );
  }
}

/// Wake up and lights out in one well, by half hours.
class DayQuestionCard extends ConsumerWidget {
  const DayQuestionCard({required this.chat, super.key});

  static const int _step = 30;

  final OnboardingChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    final card = ChatCardColors.of(context);
    final wake = form.wakeMinute;
    final bed = form.bedMinute;
    final awake = form.dayWindow.awakeMinutes;
    // A step stays put when it would leave less than the minimum awake, or
    // wrap the window all the way round.
    VoidCallback? move({int wakeBy = 0, int bedBy = 0}) {
      final next = awake - wakeBy + bedBy;
      if (next < DayWindow.minAwakeMinutes || next >= DayWindow.minutesPerDay) {
        return null;
      }
      return () =>
          chat.setDay(wakeMinute: wake + wakeBy, bedMinute: bed + bedBy);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: card.fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: card.line),
          ),
          child: Column(
            children: [
              _TimeRow(
                icon: AppIcons.morning,
                label: OnboardingCopy.upAt,
                minute: wake,
                earlierLabel: OnboardingCopy.wakeEarlier,
                laterLabel: OnboardingCopy.wakeLater,
                onEarlier: move(wakeBy: -_step),
                onLater: move(wakeBy: _step),
              ),
              Divider(height: 1, color: card.line),
              _TimeRow(
                icon: AppIcons.lateNight,
                label: OnboardingCopy.lightsOutAt,
                minute: bed,
                earlierLabel: OnboardingCopy.bedEarlier,
                laterLabel: OnboardingCopy.bedLater,
                onEarlier: move(bedBy: -_step),
                onLater: move(bedBy: _step),
              ),
            ],
          ),
        ),
        Text(
          OnboardingCopy.dayCardLine(
            OnboardingCopy.span(awake),
            OnboardingCopy.span((awake / form.startLimit).round()),
          ),
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(color: card.muted),
        ),
        CardButton(label: OnboardingCopy.thatsMyDay, onTap: chat.sendDay),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.minute,
    required this.earlierLabel,
    required this.laterLabel,
    required this.onEarlier,
    required this.onLater,
  });

  final IconData icon;
  final String label;
  final int minute;
  final String earlierLabel;
  final String laterLabel;
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, size: 18, color: card.muted),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodySmall?.copyWith(color: card.muted)),
                Text(
                  AppFormat.minuteOfDay(minute),
                  style: text.titleMedium?.copyWith(
                    color: card.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          CardRoundButton(
            icon: AppIcons.remove,
            label: earlierLabel,
            onTap: onEarlier,
          ),
          CardRoundButton(
            icon: AppIcons.add,
            label: laterLabel,
            onTap: onLater,
          ),
        ],
      ),
    );
  }
}

/// − value + in a well. [step] is how far each tap moves.
class CardStepper extends StatelessWidget {
  const CardStepper({
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.fewerLabel = OnboardingCopy.fewer,
    this.moreLabel = OnboardingCopy.more,
    super.key,
  });

  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final String fewerLabel;
  final String moreLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    final text = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: card.fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.line),
      ),
      child: Row(
        spacing: 10,
        children: [
          CardRoundButton(
            icon: AppIcons.remove,
            label: fewerLabel,
            onTap: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                RollingNumber(
                  value: value,
                  style: text.headlineSmall?.copyWith(
                    color: card.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unit,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: card.muted),
                ),
              ],
            ),
          ),
          CardRoundButton(
            icon: AppIcons.add,
            label: moreLabel,
            onTap: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

/// A 44 pt round outlined button inside a card; dimmed and inert while
/// [onTap] is null.
class CardRoundButton extends StatelessWidget {
  const CardRoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    final tap = onTap;
    return Semantics(
      button: true,
      enabled: tap != null,
      label: label,
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap == null
            ? null
            : () {
                unawaited(HapticFeedback.selectionClick());
                tap();
              },
        child: AnimatedOpacity(
          opacity: tap == null ? 0.4 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: card.card,
              shape: BoxShape.circle,
              border: Border.all(color: card.line),
            ),
            child: Icon(icon, size: 18, color: card.ink),
          ),
        ),
      ),
    );
  }
}

/// A full-width solid button inside a card.
class CardButton extends StatelessWidget {
  const CardButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
        child: PressScale(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: card.ink,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(
                color: card.card,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text field and a round send button.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.controller,
    required this.hint,
    required this.sendLabel,
    required this.maxLength,
    required this.onSend,
    this.label,
    this.autofill,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String sendLabel;
  final int maxLength;
  final ValueChanged<String> onSend;

  /// A field label for VoiceOver when it differs from [hint].
  final String? label;
  final String? autofill;

  /// Null is plain text with capitalised words.
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    final text = context.textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: card.line),
    );
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Semantics(
            label: label,
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              autofillHints: [?autofill],
              keyboardType: keyboardType,
              textCapitalization: keyboardType == null
                  ? TextCapitalization.words
                  : TextCapitalization.none,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              cursorColor: card.ink,
              style: text.bodyLarge?.copyWith(color: card.ink),
              decoration: InputDecoration(
                hintText: hint,
                hintMaxLines: 2,
                hintStyle: text.bodyLarge?.copyWith(color: card.muted),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: card.fill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: card.muted),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: sendLabel,
          onTap: () => onSend(controller.text),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              onSend(controller.text);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: card.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.send, size: 18, color: card.card),
            ),
          ),
        ),
      ],
    );
  }
}

/// An outlined pill for a secondary answer, 44 pt tall.
class _CardPill extends StatelessWidget {
  const _CardPill({
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;

  /// An answer (a price), rather than a way out.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: ShapeDecoration(
            color: strong ? card.fill : null,
            shape: StadiumBorder(side: BorderSide(color: card.line)),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: strong ? card.ink : card.muted,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A text-sized habit pill with a 44 pt tall touch area.
class _HabitPill extends StatelessWidget {
  const _HabitPill({
    required this.label,
    required this.onTap,
    this.dashed = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final card = ChatCardColors.of(context);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: ShapeDecoration(
        color: card.fill,
        shape: StadiumBorder(
          side: dashed ? BorderSide.none : BorderSide(color: card.line),
        ),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(color: card.ink),
      ),
    );
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: dashed
                ? CustomPaint(
                    foregroundPainter: _DashedStadium(color: card.muted),
                    child: pill,
                  )
                : pill,
          ),
        ),
      ),
    );
  }
}

class _DashedStadium extends CustomPainter {
  const _DashedStadium({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(0.5),
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadium old) => old.color != color;
}
