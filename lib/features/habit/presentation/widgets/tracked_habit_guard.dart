import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Keeps a page about one habit from outliving it: once [habitId] is no longer
/// tracked the app returns Home, or to onboarding with no habit left. A null
/// [habitId] is a page about every habit, which always stays.
class TrackedHabitGuard extends ConsumerStatefulWidget {
  const TrackedHabitGuard({
    required this.habitId,
    required this.child,
    super.key,
  });

  final int? habitId;
  final Widget child;

  @override
  ConsumerState<TrackedHabitGuard> createState() => _TrackedHabitGuardState();
}

class _TrackedHabitGuardState extends ConsumerState<TrackedHabitGuard> {
  bool _left = false;

  void _leave({required bool noHabitsLeft}) {
    _left = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(noHabitsLeft ? AppRoutes.onboarding : AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.habitId;
    final habits = ref.watch(activeHabitsProvider).value;
    if (!_left &&
        id != null &&
        habits != null &&
        !habits.any((habit) => habit.id == id)) {
      _leave(noHabitsLeft: habits.isEmpty);
    }
    return widget.child;
  }
}
