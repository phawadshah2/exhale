import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.today,
    required this.now,
    required this.name,
    required this.dayNumber,
    super.key,
  });

  final LogicalDay today;
  final DateTime now;
  final String? name;
  final int? dayNumber;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final greeting = AppFormat.greeting(now);

    return Row(
      children: [
        _Avatar(name: name, dayNumber: dayNumber),
        const SizedBox(width: AppSpacing.gutterSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppFormat.weekdayDate(today),
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                name == null ? greeting : '$greeting, $name',
                style: text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.dayNumber});

  final String? name;
  final int? dayNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = _initials(name);
    return SizedBox(
      width: 52,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainerHigh,
              border: Border.all(
                color: colors.primaryContainer.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: initials == null
                ? Icon(AppIcons.person, color: colors.onSurfaceVariant)
                : Text(
                    initials,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
          ),
          if (dayNumber != null)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: ShapeDecoration(
                  color: colors.primaryContainer,
                  shape: StadiumBorder(
                    side: BorderSide(color: colors.surface, width: 2),
                  ),
                ),
                child: Text(
                  'D$dayNumber',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String? _initials(String? name) {
    final parts = name
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts == null || parts.isEmpty) return null;
    final letters = parts.length == 1
        ? parts.first.substring(0, 1)
        : parts.first.substring(0, 1) + parts.last.substring(0, 1);
    return letters.toUpperCase();
  }
}
