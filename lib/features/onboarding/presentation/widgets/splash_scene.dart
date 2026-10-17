import 'dart:math' as math;
import 'dart:ui';

import 'package:exhale/core/presentation/providers/app_info_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_logo.dart';
import 'package:exhale/features/onboarding/presentation/widgets/drifting_particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splash visuals. [intro] (0 → 1) drives the staggered entrance; the scene
/// runs its own ambient loops (breathing, dot pulse, drifting dust).
class SplashScene extends StatefulWidget {
  const SplashScene({required this.intro, required this.animate, super.key});

  final Animation<double> intro;

  /// False when the platform asks for reduced motion.
  final bool animate;

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene>
    with TickerProviderStateMixin {
  static const _decelerate = Cubic(0.16, 1, 0.3, 1);
  static const _breathCycle = Duration(seconds: 6);

  /// 100 ms of the 1.8 s intro, as a fraction of its timeline.
  static const double _dotStagger = 100 / 1800;

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _breathCycle ~/ 2,
    value: 0.5,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void initState() {
    super.initState();
    _syncAmbient();
  }

  @override
  void didUpdateWidget(SplashScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncAmbient();
  }

  void _syncAmbient() {
    if (widget.animate) {
      _breath.repeat(reverse: true);
      _pulse.repeat();
      _drift.repeat();
    } else {
      _breath
        ..stop()
        ..value = 0.5;
      _pulse
        ..stop()
        ..value = 0;
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    _drift.dispose();
    super.dispose();
  }

  /// Progress of the [begin]–[end] slice of the intro, eased.
  double _phase(double begin, double end, [Curve curve = _decelerate]) {
    final raw = (widget.intro.value - begin) / (end - begin);
    return curve.transform(raw.clamp(0.0, 1.0));
  }

  double get _breathValue => Curves.easeInOutSine.transform(_breath.value);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final b = _breathValue;
            // Fade the glow itself to transparent (not to the surface colour)
            // so there is no visible edge; keep it subtler on light surfaces.
            final strength = colors.brightness == Brightness.dark ? 1.0 : 0.55;
            final glow = colors.primaryContainer;
            final alpha = (0.14 + 0.08 * b) * strength;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9 + 0.12 * b,
                  stops: const [0, 0.45, 1],
                  colors: [
                    glow.withValues(alpha: alpha),
                    glow.withValues(alpha: alpha * 0.4),
                    glow.withValues(alpha: 0),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.animate)
          DriftingParticles(animation: _drift, color: colors.primaryContainer),
        SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.intro, _breath, _pulse]),
            builder: (context, _) => Column(
              children: [
                _topBadge(context),
                Expanded(child: Center(child: _centrePiece(context))),
                _versionPill(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBadge(BuildContext context) {
    final t = _phase(0, 0.35);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, -24 * (1 - t)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CALM MODE',
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _centrePiece(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final b = _breathValue;

    final logoIn = _phase(0.05, 0.5);
    final wordIn = _phase(0.3, 0.65, const Cubic(0.22, 1, 0.36, 1));
    final tagIn = _phase(0.4, 0.75, const Cubic(0.22, 1, 0.36, 1));
    final blur = 6 * (1 - wordIn);

    Widget wordmark = Text(
      'Exhale',
      style: text.displayMedium?.copyWith(fontWeight: FontWeight.w800),
    );
    if (blur > 0.05) {
      wordmark = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: wordmark,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: logoIn,
          child: Transform.scale(
            scale: (0.6 + 0.4 * logoIn) * (0.97 + 0.06 * b),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryContainer.withValues(
                      alpha: (0.05 + 0.07 * b) * logoIn,
                    ),
                    blurRadius: 50,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const AppLogo(size: 220),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Opacity(
          opacity: wordIn,
          child: Transform.translate(
            offset: Offset(-40 * (1 - wordIn), 0),
            child: wordmark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: tagIn,
          child: Transform.translate(
            offset: Offset(40 * (1 - tagIn), 0),
            child: Text(
              'Breathe easier, one day at a time',
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _dots(context),
      ],
    );
  }

  Widget _dots(BuildContext context) {
    final color = context.colors.primaryContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final rise = _phase(0.6 + i * _dotStagger, 0.8 + i * _dotStagger);
              final pulsePhase = (_pulse.value - i / 3) % 1;
              final pulse = widget.animate
                  ? 0.35 + 0.65 * math.sin(pulsePhase * math.pi).abs()
                  : 1.0;
              return Transform.translate(
                offset: Offset(0, 10 * (1 - rise)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: rise * pulse),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _versionPill(BuildContext context) {
    final t = _phase(0.65, 1);
    final version = Consumer(
      builder: (context, ref, _) =>
          ref.watch(appVersionProvider).whenOrNull(data: _Pill.new) ??
          const SizedBox(height: 36),
    );
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 24 * (1 - t)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: version,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.version);

  final String version;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.exhale.success.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Text('v$version', style: context.textTheme.labelLarge),
        ],
      ),
    );
  }
}
