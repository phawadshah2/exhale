import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/onboarding/presentation/widgets/splash_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const introDuration = Duration(milliseconds: 1800);

  /// Pause after the intro finishes before leaving the splash.
  static const holdDuration = Duration(milliseconds: 700);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: SplashPage.introDuration,
  );

  String? _destination;
  bool _introFinished = false;
  bool _navigated = false;
  bool _started = false;
  int _playId = 0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    unawaited(_resolveDestination());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_playIntro());
  }

  Future<void> _resolveDestination() async {
    final habits = await ref.read(habitRepositoryProvider).getActive();
    final hasHabit =
        habits is Success<List<TrackedHabit>> && habits.value.isNotEmpty;
    _destination = hasHabit ? AppRoutes.home : AppRoutes.setup;
    _maybeNavigate();
  }

  /// Plays the entrance from the start. Navigation waits for the latest
  /// play to finish, so a replay tap postpones leaving.
  Future<void> _playIntro() async {
    final id = ++_playId;
    _introFinished = false;
    if (_reduceMotion) {
      _intro.value = 1;
    } else {
      try {
        await _intro.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    await Future<void>.delayed(SplashPage.holdDuration);
    if (!mounted || id != _playId) return;
    _introFinished = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    final destination = _destination;
    if (!mounted || _navigated || !_introFinished || destination == null) {
      return;
    }
    _navigated = true;
    context.go(destination);
  }

  void _replay() {
    if (_navigated) return;
    unawaited(_playIntro());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _replay,
        child: SplashScene(intro: _intro, animate: !_reduceMotion),
      ),
    );
  }
}
