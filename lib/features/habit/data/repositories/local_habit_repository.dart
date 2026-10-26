import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/models/tracked_habit_model.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';

class LocalHabitRepository implements HabitRepository {
  const LocalHabitRepository(this._localDataSource);
  final HabitLocalDataSource _localDataSource;

  static const _source = 'LocalHabitRepository';

  @override
  Stream<List<TrackedHabit>> watchActive() =>
      _localDataSource.watchActive().map(_toEntities);

  @override
  Future<Result<List<TrackedHabit>>> getActive() => guardStorage(
    _source,
    () async => _toEntities(await _localDataSource.getActive()),
  );

  @override
  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  }) => guardStorage(_source, () async {
    final row = await _localDataSource.insertHabit(
      draft.toCompanion(createdAt: createdAt),
    );
    return row.toEntity();
  });

  @override
  Future<Result<void>> update(TrackedHabit habit) async => _requireRow(
    await guardStorage(
      _source,
      () => _localDataSource.updateHabit(habit.id, habit.toCompanion()),
    ),
  );

  @override
  Future<Result<void>> archive(int id, {required DateTime at}) async =>
      _requireRow(
        await guardStorage(
          _source,
          () => _localDataSource.updateHabit(
            id,
            HabitsCompanion(archivedAt: Value(at)),
          ),
        ),
      );

  List<TrackedHabit> _toEntities(List<HabitRow> rows) =>
      rows.map((row) => row.toEntity()).toList();

  Result<void> _requireRow(Result<int> result) => switch (result) {
    Success(value: 0) => const FailureResult<void>(NotFoundFailure()),
    Success() => const Success<void>(null),
    FailureResult(:final failure) => FailureResult<void>(failure),
  };
}
