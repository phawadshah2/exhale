import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:flutter/material.dart';

/// "4 days" of the habit's spend against the selected plan's price. The
/// small label hides when [compact].
class SpendStatCard extends StatelessWidget {
  const SpendStatCard({
    required this.days,
    required this.sentence,
    this.compact = false,
    super.key,
  });

  final String days;
  final String sentence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      container: true,
      label: '$days $sentence',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color ?? colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              spacing: 14,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 84),
                  child: Text(
                    days,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(sentence, style: text.bodyMedium),
                      if (!compact)
                        Text(
                          PaywallCopy.statLabel,
                          style: text.labelSmall?.copyWith(
                            color: colors.outline,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
