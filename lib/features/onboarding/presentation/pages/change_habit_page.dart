import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The onboarding steps for a habit that takes the place of [habitId], with
/// their own form.
class ChangeHabitPage extends ConsumerStatefulWidget {
  const ChangeHabitPage({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<ChangeHabitPage> createState() => _ChangeHabitPageState();
}

class _ChangeHabitPageState extends ConsumerState<ChangeHabitPage> {
  /// Read once: the habit stops being active the moment the new one saves,
  /// and the form has to outlive that.
  late final TrackedHabit? _replaced = ref.read(habitProvider(widget.habitId));

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [replacedHabitProvider.overrideWithValue(_replaced)],
    child: const OnboardingPage(),
  );
}
