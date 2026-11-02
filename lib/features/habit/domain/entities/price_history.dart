import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:meta/meta.dart';

/// A price in force from [fromDay] until the next point.
@immutable
class PricePoint {
  const PricePoint({
    required this.fromDay,
    required this.priceCents,
    required this.unitsPerContainer,
  });

  final LogicalDay fromDay;

  /// Per container when the habit has one, else per unit. Null counts nothing
  /// from [fromDay] until the next priced point.
  final int? priceCents;
  final int unitsPerContainer;

  @override
  bool operator ==(Object other) =>
      other is PricePoint &&
      other.fromDay == fromDay &&
      other.priceCents == priceCents &&
      other.unitsPerContainer == unitsPerContainer;

  @override
  int get hashCode => Object.hash(fromDay, priceCents, unitsPerContainer);

  @override
  String toString() =>
      'PricePoint($fromDay, $priceCents per $unitsPerContainer)';
}

/// The prices of one habit over time. [_points] are oldest first.
@immutable
class PriceHistory {
  const PriceHistory.forHabit(this._habit, this._points);

  final Habit _habit;
  final List<PricePoint> _points;

  /// The price in force on [day]; days before the first point use the first
  /// point. Null when nothing is counted that day or the habit has no cost.
  double? unitPriceCentsOn(LogicalDay day) {
    if (_points.isEmpty) return null;
    final point = _points.lastWhere(
      (point) => !point.fromDay.isAfter(day),
      orElse: () => _points.first,
    );
    return _unitPrice(point);
  }

  double? get currentUnitPriceCents =>
      _points.isEmpty ? null : _unitPrice(_points.last);

  double? _unitPrice(PricePoint point) {
    final price = point.priceCents;
    if (price == null || !_habit.tracksCost) return null;
    return _habit.hasContainer
        ? price / point.unitsPerContainer
        : price.toDouble();
  }
}
