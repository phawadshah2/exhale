import 'package:meta/meta.dart';

/// What the Live Activity and the Island show.
@immutable
class ActivityContent {
  const ActivityContent({
    required this.next,
    required this.gap,
    required this.count,
    required this.limit,
    required this.daysToGo,
    required this.countingLine,
    required this.waitingLine,
  });

  /// How long past [next] the activity stays before it goes quiet.
  static const Duration quietAfter = Duration(minutes: 15);

  /// When the next one is on schedule.
  final DateTime next;

  /// The full wait the countdown runs over.
  final Duration gap;
  final int count;
  final int limit;
  final int daysToGo;
  final String countingLine;
  final String waitingLine;

  DateTime get staleAt => next.add(quietAfter);

  Map<String, Object?> toJson() => {
    'next': next.toUtc().toIso8601String(),
    'gapSeconds': gap.inSeconds,
    'count': count,
    'limit': limit,
    'daysToGo': daysToGo,
    'countingLine': countingLine,
    'waitingLine': waitingLine,
    'staleAt': staleAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ActivityContent &&
      other.next == next &&
      other.gap == gap &&
      other.count == count &&
      other.limit == limit &&
      other.daysToGo == daysToGo &&
      other.countingLine == countingLine &&
      other.waitingLine == waitingLine;

  @override
  int get hashCode =>
      Object.hash(next, gap, count, limit, daysToGo, countingLine, waitingLine);
}
