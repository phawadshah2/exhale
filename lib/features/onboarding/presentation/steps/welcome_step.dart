import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:flutter/material.dart';

/// Step 1: the pitch. A headline with "negotiating" struck out, what the
/// app does, and one button into the chat.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  static const List<IconData> _icons = [
    AppIcons.add,
    AppIcons.trendDown,
    AppIcons.pause,
    AppIcons.lock,
  ];

  /// The headline's words, then the line under it, then each row's title
  /// and its line.
  static const Duration _firstWordAt = Duration(milliseconds: 420);
  static const Duration _wordStagger = Duration(milliseconds: 180);
  static const Duration _subtitleAt = Duration(milliseconds: 1400);
  static const Duration _rowsAt = Duration(milliseconds: 1700);
  static const Duration _rowStagger = Duration(milliseconds: 330);
  static const Duration fade = Duration(milliseconds: 700);

  static Widget _word(int i, Widget word) => StepReveal(
    delay: _firstWordAt + _wordStagger * i,
    duration: fade,
    child: word,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final headline = text.displayLarge?.copyWith(
      fontSize: 50,
      height: 1,
      letterSpacing: -50 * 0.035,
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
    );

    return OnboardingStepFrame(
      button: ChevronButton(
        label: OnboardingCopy.welcomeButton,
        onPressed: () => OnboardingScope.of(context).next(),
      ),
      below: Text(
        OnboardingCopy.welcomeFinePrint,
        textAlign: TextAlign.center,
        style: text.labelSmall?.copyWith(color: colors.outline),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          StepReveal(
            child: Text(
              OnboardingCopy.brand,
              style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 13 * 0.2,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Capped, and shrunk to the width when "negotiating" would not
          // fit a line. Each word comes in after the one before.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Semantics(
              label: OnboardingCopy.welcomeTitle,
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _word(0, Text('Stop', style: headline)),
                    _word(
                      1,
                      _Struck(
                        text: OnboardingCopy.welcomeNegotiating,
                        style: headline?.copyWith(color: colors.outline),
                        lineColor: colors.onSurface,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _word(2, Text('with ', style: headline)),
                        _word(3, Text('your', style: headline)),
                      ],
                    ),
                    _word(4, Text('cravings.', style: headline)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          StepReveal(
            delay: _subtitleAt,
            duration: WelcomeStep.fade,
            child: Text(
              OnboardingCopy.welcomeBody,
              style: text.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, row) in OnboardingCopy.welcomeRows.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _HowRow(
                icon: _icons[i],
                title: row.$1,
                body: row.$2,
                at: _rowsAt + _rowStagger * i,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// [text] with a line that draws across it, left to right, once the page is
/// in. Drawn at once under Reduce Motion.
class _Struck extends StatefulWidget {
  const _Struck({
    required this.text,
    required this.style,
    required this.lineColor,
  });

  final String text;
  final TextStyle? style;
  final Color lineColor;

  @override
  State<_Struck> createState() => _StruckState();
}

class _StruckState extends State<_Struck> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: const Interval(1400 / 2100, 1, curve: Curves.easeOutCubic),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Text(widget.text, style: widget.style),
      Positioned.fill(
        left: -2,
        right: -2,
        child: Align(
          alignment: const Alignment(0, 0.06),
          child: AnimatedBuilder(
            animation: _draw,
            builder: (context, _) => Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.diagonal3Values(_draw.value, 1, 1),
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: widget.lineColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The icon and title come in at [at], the line under them just after.
class _HowRow extends StatelessWidget {
  const _HowRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.at,
  });

  final IconData icon;
  final String title;
  final String body;
  final Duration at;

  static const Duration _bodyLag = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        StepReveal(
          delay: at,
          duration: WelcomeStep.fade,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  context.theme.cardTheme.color ?? colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(icon, size: 18, color: colors.onSurface),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              StepReveal(
                delay: at,
                duration: WelcomeStep.fade,
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StepReveal(
                delay: at + _bodyLag,
                duration: WelcomeStep.fade,
                child: Text(
                  body,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
