import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:exhale/features/onboarding/presentation/widgets/typing_dots.dart';
import 'package:exhale/features/onboarding/presentation/widgets/you_bubble.dart';
import 'package:flutter/material.dart';

/// Step 1: your excuses as sent texts, Exhale's reply, then the pitch. A tap
/// shows the end state; Reduce Motion starts there.
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  static const Duration duration = Duration(milliseconds: _endMs);

  // Timeline, in ms: excuses 400 apart, "Read", typing, both replies, then
  // the headline.
  static const int _excuseGapMs = 400;
  static const int _readMs = 1100;
  static const int _typingMs = 1300;
  static const int _replyMs = 2100;
  static const int _replyGapMs = 400;
  static const int _headlineMs = 2900;
  static const int _fadeMs = 300;
  static const int _endMs = 3400;

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: WelcomeStep.duration,
  );
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _timeline.value = 1;
    } else {
      _timeline.forward();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  void _skip() {
    if (_timeline.isCompleted) return;
    _timeline
      ..stop()
      ..value = 1;
  }

  /// [child] is left out before [startMs], then fades and rises in.
  Widget _reveal(int startMs, Widget child, {double rise = 12}) {
    final elapsed = _timeline.value * WelcomeStep._endMs;
    if (elapsed < startMs) return const SizedBox.shrink();
    final t = Curves.easeOutCubic.transform(
      ((elapsed - startMs) / WelcomeStep._fadeMs).clamp(0, 1),
    );
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, rise * (1 - t)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final text = context.textTheme;
    final faint = text.labelSmall?.copyWith(color: colors.outline);
    const excuses = OnboardingCopy.excuses;
    const replies = OnboardingCopy.welcomeReplies;

    return OnboardingStepFrame(
      onTapBody: _skip,
      button: GlowButton(
        label: OnboardingCopy.welcomeButton,
        onPressed: () => OnboardingScope.of(context).next(),
      ),
      below: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          OnboardingCopy.welcomeFinePrint,
          textAlign: TextAlign.center,
          style: faint,
        ),
      ),
      body: AnimatedBuilder(
        animation: _timeline,
        builder: (context, _) {
          final elapsed = _timeline.value * WelcomeStep._endMs;
          final typing =
              elapsed >= WelcomeStep._typingMs &&
              elapsed < WelcomeStep._replyMs;
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: OnboardingCopy.welcomeSender,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: OnboardingCopy.welcomeSentAt),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: faint,
                  ),
                  const SizedBox(height: AppSpacing.gutterSm),
                  for (final (i, excuse) in excuses.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _reveal(
                        i * WelcomeStep._excuseGapMs,
                        YouBubble(
                          text: excuse,
                          continued: i > 0,
                          last: i == excuses.length - 1,
                        ),
                      ),
                    ),
                  _reveal(
                    WelcomeStep._readMs,
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 2),
                      child: Text(
                        OnboardingCopy.welcomeRead,
                        textAlign: TextAlign.right,
                        style: faint,
                      ),
                    ),
                    rise: 0,
                  ),
                  const SizedBox(height: AppSpacing.gutterSm),
                  if (typing)
                    const Padding(
                      padding: EdgeInsets.only(
                        left: ExhaleBubble.avatarSize + 9,
                        top: AppSpacing.sm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TypingDots(),
                      ),
                    ),
                  for (final (i, reply) in replies.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _reveal(
                        WelcomeStep._replyMs + i * WelcomeStep._replyGapMs,
                        ExhaleBubble(
                          text: reply,
                          showAvatar: i == replies.length - 1,
                          continued: i > 0,
                        ),
                      ),
                    ),
                ],
              ),
              _reveal(
                WelcomeStep._headlineMs,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      OnboardingCopy.welcomeTitle,
                      style: text.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      OnboardingCopy.welcomeBody,
                      style: text.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                rise: 24,
              ),
            ],
          );
        },
      ),
    );
  }
}
