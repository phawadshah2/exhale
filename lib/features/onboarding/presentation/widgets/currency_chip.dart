import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/settings/domain/entities/currency_choices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The price's currency; a tap opens a wheel of [CurrencyChoices.all].
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    required this.symbol,
    required this.onChanged,
    super.key,
  });

  final String symbol;
  final ValueChanged<String> onChanged;

  static const double itemExtent = 36;

  Future<void> _pick(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    const choices = CurrencyChoices.all;
    final index = await showOptionWheel(
      context,
      title: OnboardingCopy.currency,
      options: [for (final choice in choices) choice.symbol],
      initialIndex: choices
          .indexWhere((c) => c.symbol == symbol)
          .clamp(0, choices.length - 1),
      itemExtent: itemExtent,
    );
    if (index != null) onChanged(choices[index].symbol);
  }

  @override
  Widget build(BuildContext context) {
    final pick = SelectionColors.of(context);
    final accent = pick.foreground;
    return Semantics(
      button: true,
      label: OnboardingCopy.currency,
      value: symbol,
      onTap: () => unawaited(_pick(context)),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_pick(context)),
        child: PressScale(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: pick.fill,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              border: Border.all(color: accent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                Text(
                  symbol,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(AppIcons.chevronDown, size: 13, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
