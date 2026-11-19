import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/settings/domain/plan_tile_summary.dart';

/// The subscription tile: the plan, whether it is active, and when it
/// renews or the free week ends. [cachedPlan] is the stored `PlanKind` name.
TileSummary subscriptionTileSummary({
  required Access access,
  required String? cachedPlan,
  required DateTime now,
}) {
  switch (access) {
    case Entitled(plan: PlanKind.lifetime):
      return const TileSummary(eyebrow: 'Lifetime', value: 'Yours for good');
    case Entitled(:final plan, :final expiresAt, inTrial: true):
      final ends = expiresAt == null ? null : _day(expiresAt);
      final left = ends == null ? 0 : ends.daysSince(_day(now));
      return TileSummary(
        eyebrow: 'Free week',
        value: switch (left) {
          <= 0 => 'Ends today',
          1 => '1 day left',
          _ => '$left days left',
        },
        line: ends == null
            ? null
            : '${_name(plan)} from ${AppFormat.monthDay(ends)}',
      );
    case Entitled(:final plan, :final expiresAt):
      return TileSummary(
        eyebrow: _name(plan),
        value: 'Active',
        line: expiresAt == null
            ? null
            : 'Renews ${AppFormat.monthDay(_day(expiresAt))}',
      );
    case AccessUnknown():
      final plan = cachedPlan == null
          ? null
          : PlanKind.values.asNameMap()[cachedPlan];
      return TileSummary(
        eyebrow: plan == null ? 'Subscription' : _name(plan),
        value: "Can't check now",
      );
    // The router keeps these off Settings; shown only if that ever changes.
    case Lapsed(:final plan):
      return TileSummary(eyebrow: _name(plan), value: 'Ended');
    case NeverPaid():
      return const TileSummary(eyebrow: 'Subscription', value: 'Not active');
  }
}

LogicalDay _day(DateTime time) => LogicalDay.fromDate(time.toLocal());

String _name(PlanKind plan) => switch (plan) {
  PlanKind.annual => 'Annual',
  PlanKind.monthly => 'Monthly',
  PlanKind.lifetime => 'Lifetime',
};
