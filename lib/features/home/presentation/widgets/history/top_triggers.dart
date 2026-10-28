import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';

/// The three most used triggers of the shown period as tappable chips, with
/// a link to every trigger in Logs.
class TopTriggers extends StatelessWidget {
  const TopTriggers({
    required this.breakdown,
    required this.sinceStart,
    required this.onTrigger,
    required this.onAll,
    super.key,
  });

  final TriggerBreakdown breakdown;
  final bool sinceStart;
  final ValueChanged<Trigger> onTrigger;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final top = breakdown.top(3);
    if (top.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sinceStart ? 'TOP TRIGGERS SINCE DAY 1' : 'TOP TRIGGERS',
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text(
                      'All triggers ›',
                      style: text.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < top.length; i++)
                _Chip(
                  label:
                      '${top[i].trigger.label} · '
                      '${(top[i].fraction * 100).round()}% ›',
                  color: top[i].trigger.tint(context),
                  onTap: () => onTrigger(top[i].trigger),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
