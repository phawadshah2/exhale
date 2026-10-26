import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:meta/meta.dart';

/// A habit the user is cutting down, with their own details for it.
@immutable
class TrackedHabit {
  const TrackedHabit({
    required this.id,
    required this.habit,
    required this.createdAt,
    this.reason,
    this.priceCents,
    this.unitsPerContainer = defaultUnitsPerContainer,
    this.archivedAt,
    this.quitAcknowledgedAt,
  });

  static const int defaultUnitsPerContainer = 20;

  final int id;
  final Habit habit;

  /// The user's own words for why they are cutting down.
  final String? reason;

  /// Per container when the habit has one, else per unit.
  final int? priceCents;
  final int unitsPerContainer;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final DateTime? quitAcknowledgedAt;

  bool get isArchived => archivedAt != null;

  /// Null when no price is set or the habit has no cost.
  double? get unitPriceCents {
    final price = priceCents;
    if (price == null || !habit.tracksCost) return null;
    return habit.hasContainer ? price / unitsPerContainer : price.toDouble();
  }

  TrackedHabit copyWith({
    Habit? habit,
    String? Function()? reason,
    int? Function()? priceCents,
    int? unitsPerContainer,
    DateTime? Function()? archivedAt,
    DateTime? Function()? quitAcknowledgedAt,
  }) => TrackedHabit(
    id: id,
    habit: habit ?? this.habit,
    createdAt: createdAt,
    reason: reason != null ? reason() : this.reason,
    priceCents: priceCents != null ? priceCents() : this.priceCents,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    archivedAt: archivedAt != null ? archivedAt() : this.archivedAt,
    quitAcknowledgedAt: quitAcknowledgedAt != null
        ? quitAcknowledgedAt()
        : this.quitAcknowledgedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is TrackedHabit &&
      other.id == id &&
      other.habit == habit &&
      other.reason == reason &&
      other.priceCents == priceCents &&
      other.unitsPerContainer == unitsPerContainer &&
      other.createdAt == createdAt &&
      other.archivedAt == archivedAt &&
      other.quitAcknowledgedAt == quitAcknowledgedAt;

  @override
  int get hashCode => Object.hash(
    id,
    habit,
    reason,
    priceCents,
    unitsPerContainer,
    createdAt,
    archivedAt,
    quitAcknowledgedAt,
  );

  @override
  String toString() => 'TrackedHabit(#$id ${habit.name})';
}
