import 'package:exhale/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Fades and lifts [child] in at the pace of the rings and charts. Give it a
/// key that changes with the data to play it again.
class FillIn extends StatelessWidget {
  const FillIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.fill,
    curve: AppMotion.fillCurve,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
    ),
    child: child,
  );
}

/// A whole number that counts up from zero at the pace of [FillIn].
class CountUp extends StatelessWidget {
  const CountUp({required this.value, required this.builder, super.key});

  final int value;
  final Widget Function(BuildContext context, int shown) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: AppMotion.fill,
    curve: AppMotion.fillCurve,
    builder: (context, shown, _) => builder(context, shown.round()),
  );
}
