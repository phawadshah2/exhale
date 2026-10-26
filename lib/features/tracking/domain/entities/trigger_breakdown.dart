import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

@immutable
class TriggerShare {
  const TriggerShare({
    required this.trigger,
    required this.count,
    required this.fraction,
  });

  final Trigger trigger;
  final int count;

  /// Share of every log in the period, including logs with no trigger.
  final double fraction;

  @override
  bool operator ==(Object other) =>
      other is TriggerShare &&
      other.trigger == trigger &&
      other.count == count &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(trigger, count, fraction);

  @override
  String toString() => 'TriggerShare($trigger x$count)';
}

@immutable
class TriggerBreakdown {
  TriggerBreakdown({
    required List<TriggerShare> shares,
    required this.noTrigger,
    required this.total,
  }) : shares = List.unmodifiable(shares);

  /// Most used first; ties follow the [Trigger] order.
  final List<TriggerShare> shares;

  /// Logs saved without a trigger.
  final int noTrigger;

  final int total;

  /// The [n] most used triggers, leaving out logs with no trigger.
  List<TriggerShare> top(int n) => shares.take(n).toList();
}
