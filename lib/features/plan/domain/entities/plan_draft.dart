import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

/// Unvalidated plan input from the setup or edit forms.
@immutable
class PlanDraft {
  const PlanDraft({
    required this.startDay,
    required this.startLimit,
    required this.quitDay,
  });

  final LogicalDay startDay;
  final int startLimit;
  final LogicalDay quitDay;

  int get totalDays => quitDay.daysSince(startDay);

  PlanDraft copyWith({
    LogicalDay? startDay,
    int? startLimit,
    LogicalDay? quitDay,
  }) => PlanDraft(
    startDay: startDay ?? this.startDay,
    startLimit: startLimit ?? this.startLimit,
    quitDay: quitDay ?? this.quitDay,
  );

  @override
  bool operator ==(Object other) =>
      other is PlanDraft &&
      other.startDay == startDay &&
      other.startLimit == startLimit &&
      other.quitDay == quitDay;

  @override
  int get hashCode => Object.hash(startDay, startLimit, quitDay);
}
