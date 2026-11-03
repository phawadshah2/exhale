import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:exhale/features/plan/presentation/providers/edit_plan_provider.dart';
import 'package:exhale/features/plan/presentation/widgets/edit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The price on Edit plan, what it comes to, and what the page will save.
class PriceCard extends StatefulWidget {
  const PriceCard({
    required this.habit,
    required this.form,
    required this.currencySymbol,
    required this.baseline,
    required this.countsFromDayOne,
    required this.onPriceChanged,
    required this.onUnitsChanged,
    super.key,
  });

  final Habit habit;
  final EditPlanState form;
  final String currencySymbol;

  /// True while a price saved today would be the habit's first.
  final bool countsFromDayOne;

  /// The daily amount before the first plan.
  final int baseline;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<int> onUnitsChanged;

  @override
  State<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard> {
  // From the form, as the list can drop this card once it scrolls away.
  late final TextEditingController _price = TextEditingController(
    text: widget.form.priceText,
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _price.dispose();
    _focus.dispose();
    super.dispose();
  }

  double _unitPrice(int cents, int units) =>
      widget.habit.hasContainer ? cents / units : cents.toDouble();

  String _money(num cents, {bool wholeUnits = false}) => AppFormat.money(
    cents,
    symbol: widget.currencySymbol,
    wholeUnits: wholeUnits,
  );

  void _ratherNotKnow() {
    _price.clear();
    widget.onPriceChanged('');
  }

  void _stepUnits(int by) {
    unawaited(HapticFeedback.selectionClick());
    widget.onUnitsChanged(widget.form.unitsPerContainer + by);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final habit = widget.habit;
    final form = widget.form;
    final title = habit.hasContainer
        ? 'Price of a ${habit.container}'
        : 'Price of one ${habit.unit}';
    final stored = form.storedPriceCents;
    final cents = form.hasInvalidPrice ? null : form.priceCents;
    final unit = cents == null
        ? null
        : _unitPrice(cents, form.unitsPerContainer);
    final storedUnit = stored == null
        ? null
        : _unitPrice(stored, form.storedUnits);
    final fine = Text(
      widget.countsFromDayOne
          ? 'Counts from Day 1.'
          : "Counts from today. What you've saved so far stays as it is.",
      style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
    );
    final rather = form.priceText.trim().isEmpty
        ? null
        : TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
              textStyle: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: _ratherNotKnow,
            child: const Text("I'd rather not know"),
          );
    final large = context.hasLargeText;

    return EditCard(
      title: title,
      side: stored != null && form.priceCents != stored
          ? Text(
              'Was ${_money(stored)}',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            )
          : null,
      children: [
        if (!habit.hasContainer)
          _field(title)
        else if (large) ...[
          _field(title),
          Center(child: _stepper(habit)),
        ] else
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: _field(title)),
              _stepper(habit),
            ],
          ),
        if (form.hasInvalidPrice)
          Text(
            'Enter a valid price',
            style: text.bodySmall?.copyWith(
              color: context.exhale.danger.foreground,
            ),
          ),
        if (unit != null) _tiles(habit, unit, large: large),
        if (unit != null && storedUnit != null && unit != storedUnit)
          ExhaleReply(
            text: unit > storedUnit
                ? 'Up again? Almost like they want you to quit.'
                : "Cheaper? Don't celebrate with one.",
          ),
        if (large)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fine, ?rather],
          )
        else
          Row(
            spacing: AppSpacing.gutterSm,
            children: [
              Expanded(child: fine),
              ?rather,
            ],
          ),
      ],
    );
  }

  Widget _field(String label) {
    final colors = context.colors;
    final text = context.textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _focus.requestFocus,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.exhale.inset,
          borderRadius: AppRadius.inner,
        ),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Text(
              widget.currencySymbol,
              style: text.titleMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            Expanded(
              child: MergeSemantics(
                child: Semantics(
                  label: label,
                  child: TextField(
                    controller: _price,
                    focusNode: _focus,
                    onChanged: widget.onPriceChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                    ],
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    // Fills the box, so VoiceOver gets the whole 52 pt too.
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(Habit habit) {
    final colors = context.colors;
    final text = context.textTheme;
    final units = widget.form.unitsPerContainer;
    final container = habit.container;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        RoundIconButton(
          icon: AppIcons.remove,
          label: 'Fewer ${habit.units} in a $container',
          size: 44,
          onTap: units > 1 ? () => _stepUnits(-1) : null,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$units',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'a $container',
              style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        RoundIconButton(
          icon: AppIcons.add,
          label: 'More ${habit.units} in a $container',
          size: 44,
          onTap: units < HabitValidation.maxUnitsPerContainer
              ? () => _stepUnits(1)
              : null,
        ),
      ],
    );
  }

  Widget _tiles(Habit habit, double unit, {required bool large}) {
    final one = _Tile(label: 'One ${habit.unit}', value: _money(unit));
    final year = _Tile(
      label: 'At your old ${widget.baseline} a day',
      value: '${_money(unit * widget.baseline * 365, wholeUnits: true)} a year',
    );
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [one, year],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Expanded(child: one),
          Expanded(child: year),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.exhale.inset,
        borderRadius: AppRadius.inner,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
