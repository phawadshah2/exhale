import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/widgets/load_failure.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plan reveal for a saved plan that was never paid for or logged,
/// from today.
class WelcomeBackPage extends ConsumerStatefulWidget {
  const WelcomeBackPage({super.key});

  static const pageKey = Key('welcome-back-page');

  @override
  ConsumerState<WelcomeBackPage> createState() => _WelcomeBackPageState();
}

class _WelcomeBackPageState extends ConsumerState<WelcomeBackPage> {
  /// Read once: saving replaces the plan, and the form has to outlive that.
  ({TrackedHabit habit, ReductionPlan plan})? _resumed;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    final habits = await ref.read(habitRepositoryProvider).getActive();
    if (!mounted) return;
    if (habits case Success(value: [final habit, ...])) {
      final history = await ref
          .read(planRepositoryProvider)
          .getHistory(habit.id);
      if (!mounted) return;
      if (history case Success(value: final history?)) {
        setState(() => _resumed = (habit: habit, plan: history.current));
        return;
      }
    }
    setState(() => _failed = true);
  }

  void _retry() {
    setState(() => _failed = false);
    unawaited(_read());
  }

  @override
  Widget build(BuildContext context) {
    final resumed = _resumed;
    if (resumed == null) {
      return Scaffold(
        key: WelcomeBackPage.pageKey,
        body: _failed
            ? LoadFailure(message: "Couldn't open your plan.", onRetry: _retry)
            : null,
      );
    }
    return KeyedSubtree(
      key: WelcomeBackPage.pageKey,
      child: ProviderScope(
        overrides: [resumedPlanProvider.overrideWithValue(resumed)],
        child: const OnboardingPage(),
      ),
    );
  }
}
