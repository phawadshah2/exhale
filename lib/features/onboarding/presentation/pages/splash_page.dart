import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/widgets/load_failure.dart';
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

  /// First launch: how long "We need to talk." shows before Welcome.
  static const firstLaunchDuration = Duration(milliseconds: 1200);

  /// First launch: the entrance, shortened from [introDuration].
  static const firstLaunchEntrance = Duration(milliseconds: 450);

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
  Timer? _leave;
  bool _talking = false;
  bool _introFinished = false;
  bool _navigated = false;
  bool _started = false;
  bool _readFailed = false;
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
    switch (habits) {
      case Success(value: [_, ...]):
        _destination = AppRoutes.home;
        _maybeNavigate();
      case Success():
        _startTalking();
      // A returning user must not land in onboarding as if their data had gone.
      case FailureResult():
        if (mounted) setState(() => _readFailed = true);
    }
  }

  void _retryRead() {
    setState(() => _readFailed = false);
    unawaited(_resolveDestination());
  }

  /// First launch: no long intro, a short line, then onboarding.
  void _startTalking() {
    if (!mounted) return;
    _playId++;
    setState(() => _talking = true);
    if (_reduceMotion) {
      _intro.value = 1;
    } else {
      _intro.animateTo(
        1,
        duration: SplashPage.firstLaunchEntrance,
        curve: Curves.easeOut,
      );
    }
    _leave = Timer(SplashPage.firstLaunchDuration, () {
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go(AppRoutes.onboarding);
    });
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
    if (_navigated || _talking) return;
    unawaited(_playIntro());
  }

  @override
  void dispose() {
    _leave?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_readFailed) {
      return Scaffold(
        body: LoadFailure(
          message: "Couldn't open your data.",
          onRetry: _retryRead,
        ),
      );
    }
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _replay,
        child: SplashScene(
          intro: _intro,
          animate: !_reduceMotion,
          talking: _talking,
        ),
      ),
    );
  }
}
