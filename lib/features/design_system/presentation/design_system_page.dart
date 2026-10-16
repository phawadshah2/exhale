import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Living style guide: every token and themed component in one scroll.
/// Used to check the theme against the Stitch screens in both modes.
class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: AppSpacing.page.copyWith(bottom: AppSpacing.xl),
        children: const [
          _ThemeModeSection(),
          _Section(title: 'Colours', child: _ColourSection()),
          _Section(title: 'Typography', child: _TypeScale()),
          _Section(title: 'Buttons', child: _Buttons()),
          _Section(title: 'Trigger chips', child: _TriggerChips()),
          _Section(title: 'Limit states', child: _LimitStates()),
          _Section(title: 'Cards', child: _StatCards()),
          _Section(title: 'Feedback', child: _Feedback()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.gutterSm),
          child,
        ],
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(title: 'Theme', child: ThemePreferenceControl());
  }
}

class _ColourSection extends StatelessWidget {
  const _ColourSection();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.exhale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwatchRow([
          ('primary', c.primary),
          ('primaryContainer', c.primaryContainer),
          ('onSurface', c.onSurface),
          ('onSurfaceVariant', c.onSurfaceVariant),
        ]),
        const SizedBox(height: AppSpacing.gutterSm),
        _SwatchRow([
          ('surface', c.surface),
          ('containerLow', c.surfaceContainerLow),
          ('container', c.surfaceContainer),
          ('containerHigh', c.surfaceContainerHigh),
        ]),
        const SizedBox(height: AppSpacing.gutterSm),
        _SwatchRow([
          ('success', s.success.solid),
          ('warning', s.warning.solid),
          ('danger', s.danger.solid),
          ('outlineVariant', c.outlineVariant),
        ]),
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow(this.swatches);

  final List<(String, Color)> swatches;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, color) in swatches)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  name,
                  style: context.textTheme.labelSmall,
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

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.textTheme;
    final styles = <(String, TextStyle?, String)>[
      ('displayLarge', t.displayLarge, '4 / 9'),
      ('displayMedium', t.displayMedium, r'$18.85'),
      ('headlineLarge', t.headlineLarge, 'Plan Overview'),
      ('headlineMedium', t.headlineMedium, '5 left today'),
      ('headlineSmall', t.headlineSmall, 'Smoking History'),
      ('titleLarge', t.titleLarge, 'Weekly Milestones'),
      ('titleMedium', t.titleMedium, 'Log a smoke'),
      ('bodyLarge', t.bodyLarge, 'Gentle reduction gives your body time.'),
      ('bodyMedium', t.bodyMedium, 'Every 7 days your limit drops by 1.'),
      ('bodySmall', t.bodySmall, 'Since Day 1'),
      ('labelLarge', t.labelLarge, 'Save trigger'),
      ('labelMedium', t.labelMedium, 'Avg 5.7/day'),
      ('labelSmall', t.labelSmall, 'CURRENT PHASE'),
    ];

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.gutterSm,
          children: [
            for (final (name, style, sample) in styles)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: t.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(sample, style: style),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.gutterSm,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: context.exhale.accentGlow,
          ),
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Symbols.local_fire_department),
            label: const Text('Log a smoke'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Symbols.tune),
          label: const Text('Adjust reduction pace'),
        ),
        TextButton(onPressed: () {}, child: const Text('Skip')),
      ],
    );
  }
}

class _TriggerChips extends StatefulWidget {
  const _TriggerChips();

  @override
  State<_TriggerChips> createState() => _TriggerChipsState();
}

class _TriggerChipsState extends State<_TriggerChips> {
  static const List<(String, IconData)> _triggers = [
    ('Coffee', Symbols.coffee),
    ('Stress', Symbols.bolt),
    ('After meal', Symbols.restaurant),
    ('Social', Symbols.group),
    ('Boredom', Symbols.hourglass_empty),
    ('Habit', Symbols.repeat),
    ('Commute', Symbols.directions_car),
    ('Drinks', Symbols.local_bar),
  ];

  String _selected = 'Coffee';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, icon) in _triggers)
          FilterChip(
            label: Text(label),
            avatar: Icon(icon, size: 18),
            showCheckmark: false,
            selected: label == _selected,
            onSelected: (_) => setState(() => _selected = label),
          ),
      ],
    );
  }
}

/// The three colours the home ring and chart bars use. The real
/// under/at/over rule comes with the domain layer; this is a static demo.
class _LimitStates extends StatelessWidget {
  const _LimitStates();

  static const _limit = 9;
  static const _week = [7, 6, 9, 11, 4, 9, 3];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final s = context.exhale;
    final accent = context.colors.primaryContainer;

    Color barColor(int count) => count > _limit
        ? s.danger.solid
        : count == _limit
        ? s.warning.solid
        : accent;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusBadge(label: 'On track', colors: s.success),
                _StatusBadge(label: 'At limit', colors: s.warning),
                _StatusBadge(label: '2 over', colors: s.danger),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: AppSpacing.gutterSm,
                children: [
                  for (var i = 0; i < _week.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${_week[i]}',
                            style: context.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            height: _week[i] * 8.0,
                            decoration: BoxDecoration(
                              color: barColor(_week[i]),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _days[i],
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.colors});

  final String label;
  final StatusColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutterSm,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: colors.soft,
        shape: StadiumBorder(side: BorderSide(color: colors.foreground)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs + 2,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards();

  @override
  Widget build(BuildContext context) {
    final success = context.exhale.success.foreground;

    return Row(
      spacing: AppSpacing.gutterSm,
      children: [
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '4 Days',
            caption: 'within limit',
            icon: Symbols.local_fire_department,
            accent: success,
          ),
        ),
        Expanded(
          child: _StatCard(
            label: 'Money saved',
            value: r'$18.85',
            caption: 'Since Day 1',
            icon: Symbols.savings,
            accent: success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.textTheme;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: t.labelMedium)),
                Icon(icon, size: 20, color: accent),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: t.headlineMedium),
            Text(caption, style: t.bodySmall?.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback();

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.gutterSm,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Logged at 3:42 PM'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            ),
            child: const Text('Snackbar'),
          ),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What triggered this smoke?',
                      style: context.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Understanding patterns helps identify cravings.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _TriggerChips(),
                  ],
                ),
              ),
            ),
            child: const Text('Bottom sheet'),
          ),
        ),
      ],
    );
  }
}
