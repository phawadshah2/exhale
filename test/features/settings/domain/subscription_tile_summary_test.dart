import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/settings/domain/plan_tile_summary.dart';
import 'package:exhale/features/settings/domain/subscription_tile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 19, 9);

  TileSummary trialEnding(DateTime expiresAt) => subscriptionTileSummary(
    access: Entitled(
      plan: PlanKind.annual,
      expiresAt: expiresAt,
      inTrial: true,
    ),
    cachedPlan: null,
    now: now,
  );

  test('a trial counts its days left', () {
    expect(
      trialEnding(DateTime(2026, 11, 24, 8)),
      const TileSummary(
        eyebrow: 'Free week',
        value: '5 days left',
        line: 'Annual from Nov 24',
      ),
    );
  });

  test('a trial ending tomorrow says 1 day left', () {
    expect(trialEnding(DateTime(2026, 11, 20, 23)).value, '1 day left');
  });

  test('trial ending today says Ends today', () {
    expect(trialEnding(DateTime(2026, 11, 19, 22)).value, 'Ends today');
  });

  test('a passed trial end still says Ends today', () {
    expect(trialEnding(DateTime(2026, 11, 17, 22)).value, 'Ends today');
  });

  test('Annual is active and renews', () {
    expect(
      subscriptionTileSummary(
        access: Entitled(
          plan: PlanKind.annual,
          expiresAt: DateTime(2027, 11, 19, 9),
          inTrial: false,
        ),
        cachedPlan: 'annual',
        now: now,
      ),
      const TileSummary(
        eyebrow: 'Annual',
        value: 'Active',
        line: 'Renews Nov 19',
      ),
    );
  });

  test('Monthly is active and renews', () {
    expect(
      subscriptionTileSummary(
        access: Entitled(
          plan: PlanKind.monthly,
          expiresAt: DateTime(2026, 12, 3, 9),
          inTrial: false,
        ),
        cachedPlan: 'monthly',
        now: now,
      ),
      const TileSummary(
        eyebrow: 'Monthly',
        value: 'Active',
        line: 'Renews Dec 3',
      ),
    );
  });

  test('Lifetime is yours for good', () {
    expect(
      subscriptionTileSummary(
        access: const Entitled(
          plan: PlanKind.lifetime,
          expiresAt: null,
          inTrial: false,
        ),
        cachedPlan: 'lifetime',
        now: now,
      ),
      const TileSummary(eyebrow: 'Lifetime', value: 'Yours for good'),
    );
  });

  test('unknown access names the cached plan', () {
    expect(
      subscriptionTileSummary(
        access: const AccessUnknown(),
        cachedPlan: 'monthly',
        now: now,
      ),
      const TileSummary(eyebrow: 'Monthly', value: "Can't check now"),
    );
  });

  test('unknown access with no cached plan says Subscription', () {
    expect(
      subscriptionTileSummary(
        access: const AccessUnknown(),
        cachedPlan: null,
        now: now,
      ),
      const TileSummary(eyebrow: 'Subscription', value: "Can't check now"),
    );
  });
}
