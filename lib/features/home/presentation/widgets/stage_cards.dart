import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/home/presentation/providers/stage_card_provider.dart';
import 'package:exhale/features/home/presentation/widgets/stage_sheets.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The hold, review or reassess card of [habitId]'s plan, if one waits.
class StageCards extends ConsumerWidget {
  const StageCards({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    stageCardProvider(habitId),
  )) {
    final HoldCardData card => _HoldCard(habitId: habitId, card: card),
    final ReviewCardData card => _NoticeCard(
      title: "This pace isn't fitting.",
      body: '${_overLine(card.limit)} The plan can bend, and you decide how.',
      button: 'Review my plan',
      onPressed: () => unawaited(showReviewSheet(context, card)),
    ),
    final ReassessCardData card => _NoticeCard(
      title: 'Back around where you started.',
      body: "About ${card.average} a day lately. Nothing's been wiped.",
      button: 'Have a look',
      onPressed: () => unawaited(showReassessSheet(context, card)),
    ),
    null => const SizedBox.shrink(),
  };
}

const double _buttonHeight = 44;

String _overLine(int? limit) => limit == null
    ? 'Two weeks over your limit.'
    : 'Two weeks over $limit a day.';

class _Frame extends StatelessWidget {
  const _Frame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: children,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: text.titleMedium),
        Text(
          body,
          style: text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A review or reassess card: one button, no dismiss.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _Frame(
    children: [
      _Heading(title: title, body: body),
      FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_buttonHeight),
        ),
        onPressed: () {
          unawaited(HapticFeedback.selectionClick());
          onPressed();
        },
        child: Text(button, textAlign: TextAlign.center),
      ),
    ],
  );
}

class _HoldCard extends ConsumerStatefulWidget {
  const _HoldCard({required this.habitId, required this.card});

  final int habitId;
  final HoldCardData card;

  @override
  ConsumerState<_HoldCard> createState() => _HoldCardState();
}

class _HoldCardState extends ConsumerState<_HoldCard> {
  bool _saving = false;

  /// One save at a time: a second press while one is running does nothing.
  Future<void> _save(Future<Result<void>> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    unawaited(HapticFeedback.selectionClick());
    final result = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case FailureResult(:final failure)) {
      showAppSnackBar(
        context,
        message: failureMessage(failure),
        tone: SnackTone.danger,
      );
    }
  }

  Future<void> _gotIt() => _save(
    () => ref.read(answerStageCheckProvider)((
      habitId: widget.habitId,
      planStartDay: widget.card.planStartDay,
      windowEndDay: widget.card.windowEndDay,
    )),
  );

  Future<void> _keep() => _save(
    () => ref.read(keepOriginalDateProvider)((
      habitId: widget.habitId,
      planStartDay: widget.card.planStartDay,
      windowEndDay: widget.card.windowEndDay,
      holdStart: widget.card.holdStart,
    )),
  );

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final today = ref.watch(todayProvider);
    final wasNextDrop = card.wasNextDrop == today
        ? 'Was today'
        : 'Was ${AppFormat.monthDay(card.wasNextDrop)}';
    final keepDate = AppFormat.monthDay(card.wasQuitDay);
    final stayUntil = card.isLateOpen
        ? 'until ${AppFormat.monthDay(card.nextDrop)}'
        : 'for one more week';
    const size = Size.fromHeight(_buttonHeight);
    return _Frame(
      children: [
        _Heading(
          title: card.nextLimit == 0
              ? 'Zero can wait.'
              : '${card.nextLimit} can wait.',
          body:
              'Last week came to ${card.logged} against an allowed '
              '${card.allowed}, so you stay at ${card.limit} $stayUntil. '
              "Nothing's lost.",
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: _Tile(
                label: 'Next drop',
                value: AppFormat.monthDay(card.nextDrop),
                note: wasNextDrop,
              ),
            ),
            Expanded(
              child: _Tile(
                label: 'Quit date',
                value: AppFormat.monthDay(card.quitDay),
                note: 'Was $keepDate',
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            if (card.offersKeep)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: size),
                  onPressed: () => unawaited(_keep()),
                  child: Text('Keep $keepDate', textAlign: TextAlign.center),
                ),
              ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: size),
                onPressed: () => unawaited(_gotIt()),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
        if (card.offersKeep)
          Text(
            'Keep $keepDate moves you to ${card.keepLimit} today. You can '
            'choose it until tonight, then Edit plan is the way.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = text.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: '$label, $value, $note',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: muted),
            Text(
              value,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(note, style: muted),
          ],
        ),
      ),
    );
  }
}
