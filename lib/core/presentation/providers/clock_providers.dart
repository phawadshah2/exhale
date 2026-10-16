import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockProvider = Provider<Clock>((ref) => sl<Clock>());

/// Ticks once a minute so day rollover and "time since last" stay fresh.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => clock.now(),
  );
});
