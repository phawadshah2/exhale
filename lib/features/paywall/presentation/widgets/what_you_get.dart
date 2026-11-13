import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:flutter/material.dart';

/// "WHAT YOU GET": lines that need no price. [compact] drops the middle one.
class WhatYouGet extends StatelessWidget {
  const WhatYouGet({required this.startLimit, this.compact = false, super.key});

  final int startLimit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final lines = [
      (PaywallCopy.taper(startLimit), PaywallCopy.taperValue),
      if (!compact) (PaywallCopy.moreTime, PaywallCopy.moreTimeValue),
      (PaywallCopy.dataLeaves, PaywallCopy.dataLeavesValue),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          header: true,
          child: Text(
            PaywallCopy.whatYouGet,
            style: text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ),
        for (final (label, value) in lines)
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: context.exhale.emphasis,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.check,
                    size: 12,
                    color: context.exhale.onEmphasis,
                  ),
                ),
                Expanded(child: Text(label, style: text.bodyMedium)),
                Text(
                  value,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
