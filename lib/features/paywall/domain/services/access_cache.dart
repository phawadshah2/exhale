import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';

/// How long after a cached subscription's end date the app still opens when
/// the App Store cannot answer; matches the store's billing grace period.
const Duration accessGrace = Duration(days: 16);

const _entitled = 'entitled';
const _lapsed = 'lapsed';
const _neverPaid = 'neverPaid';

/// [settings] with [live] cached; [AccessUnknown] leaves them unchanged. The
/// trial flag is not cached.
AppSettings withCachedAccess(AppSettings settings, Access live) {
  final (String? state, PlanKind? plan, DateTime? until) = switch (live) {
    Entitled(:final plan, :final expiresAt) => (_entitled, plan, expiresAt),
    Lapsed(:final plan, :final endedAt) => (_lapsed, plan, endedAt),
    NeverPaid() => (_neverPaid, null, null),
    AccessUnknown() => (null, null, null),
  };
  if (state == null) return settings;
  return settings.copyWith(
    accessState: () => state,
    accessPlan: () => plan?.name,
    accessUntil: () => until,
  );
}

/// [live] when the store answered; otherwise the access cached in
/// [settings], or [AccessUnknown] when nothing usable is cached.
Access effectiveAccess(Access live, AppSettings settings, DateTime now) {
  if (live is! AccessUnknown) return live;
  final plan = PlanKind.values.asNameMap()[settings.accessPlan];
  if (plan == null) return const AccessUnknown();
  final until = settings.accessUntil;
  switch (settings.accessState) {
    case _entitled when plan == PlanKind.lifetime:
      return const Entitled(
        plan: PlanKind.lifetime,
        expiresAt: null,
        inTrial: false,
      );
    case _entitled when until != null:
      return now.isAfter(until.add(accessGrace))
          ? Lapsed(plan: plan, endedAt: until)
          : Entitled(plan: plan, expiresAt: until, inTrial: false);
    case _lapsed:
      return Lapsed(plan: plan, endedAt: until);
  }
  return const AccessUnknown();
}
