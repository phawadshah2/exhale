import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LogsQuery round-trips through a URI', () {
    final query = LogsQuery(
      habitId: 3,
      from: LogicalDay(2026, 10, 12),
      to: LogicalDay(2026, 10, 18),
      trigger: Trigger.afterMeal,
    );

    expect(query.toUri().toString(), startsWith('/logs?'));
    expect(LogsQuery.fromUri(query.toUri()), query);
  });

  test('a query with nothing set means every habit and the current week', () {
    const query = LogsQuery();

    expect(query.toUri().toString(), '/logs?habit=all');
    expect(LogsQuery.fromUri(query.toUri()), query);
  });

  test('unreadable or half-set parameters are ignored', () {
    final query = LogsQuery.fromUri(
      Uri.parse('/logs?habit=x&from=2026-10-12&trigger=nope'),
    );

    expect(query, const LogsQuery());
    expect(
      LogsQuery.fromUri(Uri.parse('/logs?from=2026-10-18&to=2026-10-12')),
      const LogsQuery(),
    );
  });
}
