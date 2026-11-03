import 'dart:async';
import 'dart:developer' as developer;

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef _CheckTarget = ({int habitId, LogicalDay today});

/// The habit and day to check; null until the habit has loaded.
final _checkTargetProvider = Provider<_CheckTarget?>((ref) {
  final habitId = ref.watch(singleHabitIdProvider);
  if (habitId == null) return null;
  return (habitId: habitId, today: ref.watch(todayProvider));
});

/// Runs the stage check once the habit has loaded and again each time the
/// logical day changes. A failure is logged and shown to no one; the check
/// simply runs again at the next start or day change.
class StageCheckListener extends ConsumerStatefulWidget {
  const StageCheckListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<StageCheckListener> createState() => _StageCheckListenerState();
}

class _StageCheckListenerState extends ConsumerState<StageCheckListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<_CheckTarget?>(_checkTargetProvider, (_, target) {
      if (target != null) unawaited(_run(target));
    }, fireImmediately: true);
  }

  Future<void> _run(_CheckTarget target) async {
    final result = await ref.read(runStageCheckProvider)((
      habitId: target.habitId,
      today: target.today,
      boundary: ref.read(dayBoundaryProvider),
    ));
    if (result case FailureResult(:final failure)) {
      developer.log('Stage check failed: $failure', name: 'StageCheckListener');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
