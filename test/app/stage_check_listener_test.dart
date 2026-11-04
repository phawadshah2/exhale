import 'package:exhale/app/shell/stage_check_listener.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/usecases/run_stage_check.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Calls implements RunStageCheck {
  final List<RunStageCheckInput> inputs = [];

  @override
  Future<Result<void>> call(RunStageCheckInput input) async {
    inputs.add(input);
    return const Success<void>(null);
  }
}

class _Day extends Notifier<LogicalDay> {
  @override
  LogicalDay build() => LogicalDay(2026, 11, 9);

  // A test helper that moves the state, not a property.
  // ignore: use_setters_to_change_properties
  void set(LogicalDay day) => state = day;
}

class _HabitId extends Notifier<int?> {
  @override
  int? build() => null;

  // A test helper that moves the state, not a property.
  // ignore: use_setters_to_change_properties
  void set(int? id) => state = id;
}

final _day = NotifierProvider<_Day, LogicalDay>(_Day.new);
final _habitId = NotifierProvider<_HabitId, int?>(_HabitId.new);

void main() {
  late _Calls calls;
  late ProviderContainer container;
  var rebuilds = 0;

  Future<void> pumpListener(WidgetTester tester, {int? habitId = 1}) async {
    calls = _Calls();
    rebuilds = 0;
    container = ProviderContainer(
      overrides: [
        runStageCheckProvider.overrideWithValue(calls),
        todayProvider.overrideWith((ref) => ref.watch(_day)),
        singleHabitIdProvider.overrideWith((ref) => ref.watch(_habitId)),
      ],
    );
    addTearDown(container.dispose);
    container.read(_habitId.notifier).set(habitId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StageCheckListener(
            child: Builder(
              builder: (context) {
                rebuilds++;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('runs once at start for the habit and day', (tester) async {
    await pumpListener(tester);

    expect(calls.inputs, hasLength(1));
    expect(calls.inputs.single.habitId, 1);
    expect(calls.inputs.single.today, LogicalDay(2026, 11, 9));
  });

  testWidgets('does not run again on a rebuild', (tester) async {
    await pumpListener(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: StageCheckListener(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    expect(calls.inputs, hasLength(1));
    expect(rebuilds, 1);
  });

  testWidgets('runs again when the logical day changes', (tester) async {
    await pumpListener(tester);

    container.read(_day.notifier).set(LogicalDay(2026, 11, 10));
    await tester.pump();

    expect(calls.inputs, hasLength(2));
    expect(calls.inputs.last.today, LogicalDay(2026, 11, 10));
  });

  testWidgets('waits for the habit, then runs', (tester) async {
    await pumpListener(tester, habitId: null);
    expect(calls.inputs, isEmpty);

    container.read(_habitId.notifier).set(7);
    await tester.pump();

    expect(calls.inputs, hasLength(1));
    expect(calls.inputs.single.habitId, 7);
  });
}
