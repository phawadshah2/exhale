import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

class PillSegment<T> {
  const PillSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Capsule track with a sliding pill thumb, as used for Week | Month and
/// Light | Dark | System in the designs. Material's SegmentedButton draws
/// bordered boxes instead, so this is custom.
class PillSegmentedControl<T> extends StatelessWidget {
  const PillSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(segments.length > 1, 'Needs at least two segments');

  final List<PillSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = segments.indexWhere((s) => s.value == selected);
    // Alignment.x runs from -1 (first segment) to 1 (last segment).
    final thumbX = -1 + 2 * index / (segments.length - 1);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment(thumbX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / segments.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.primaryContainer,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: _SegmentLabel(segment: segment, parent: this),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({required this.segment, required this.parent});

  final PillSegment<T> segment;
  final PillSegmentedControl<T> parent;

  @override
  Widget build(BuildContext context) {
    final isSelected = segment.value == parent.selected;
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: isSelected ? null : () => parent.onChanged(segment.value),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: PillSegmentedControl._duration,
            style: context.textTheme.labelLarge!.copyWith(
              color: isSelected
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
            child: Text(segment.label),
          ),
        ),
      ),
    );
  }
}
