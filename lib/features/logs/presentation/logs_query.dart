import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// What the Logs page opens on. A null [habitId] means every habit; [from]
/// and [to] are set together, or both left out for the current week.
@immutable
class LogsQuery {
  const LogsQuery({this.habitId, this.from, this.to, this.trigger});

  factory LogsQuery.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final from = _day(params['from']);
    final to = _day(params['to']);
    final ranged = from != null && to != null && !to.isBefore(from);
    return LogsQuery(
      habitId: int.tryParse(params['habit'] ?? ''),
      from: ranged ? from : null,
      to: ranged ? to : null,
      trigger: Trigger.values.asNameMap()[params['trigger']],
    );
  }

  final int? habitId;
  final LogicalDay? from;
  final LogicalDay? to;
  final Trigger? trigger;

  Uri toUri() => Uri(
    path: AppRoutes.logs,
    queryParameters: {
      'habit': habitId?.toString() ?? 'all',
      if (from != null && to != null) ...{
        'from': from.toString(),
        'to': to.toString(),
      },
      if (trigger != null) 'trigger': trigger!.name,
    },
  );

  static LogicalDay? _day(String? value) {
    if (value == null) return null;
    try {
      return LogicalDay.parse(value);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LogsQuery &&
      other.habitId == habitId &&
      other.from == from &&
      other.to == to &&
      other.trigger == trigger;

  @override
  int get hashCode => Object.hash(habitId, from, to, trigger);
}

void openLogs(BuildContext context, LogsQuery query) =>
    context.push(query.toUri().toString());
