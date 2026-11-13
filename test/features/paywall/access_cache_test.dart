import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/services/access_cache.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 13, 9);
  const blank = AppSettings(userName: 'Sam');

  AppSettings cached(String state, {String? plan, DateTime? until}) =>
      blank.copyWith(
        accessState: () => state,
        accessPlan: () => plan,
        accessUntil: () => until,
      );

  group('effectiveAccess', () {
    test('a known live access is returned as is', () {
      final entitled = Entitled(
        plan: PlanKind.annual,
        expiresAt: now.add(const Duration(days: 5)),
        inTrial: true,
      );
      final lapsedCache = cached('lapsed', plan: 'monthly', until: now);
      for (final live in <Access>[
        entitled,
        const NeverPaid(),
        Lapsed(plan: PlanKind.monthly, endedAt: now),
      ]) {
        expect(effectiveAccess(live, lapsedCache, now), live);
        expect(effectiveAccess(live, blank, now), live);
      }
    });

    test('unknown with a cached Lifetime is Entitled', () {
      expect(
        effectiveAccess(
          const AccessUnknown(),
          cached('entitled', plan: 'lifetime'),
          now,
        ),
        const Entitled(
          plan: PlanKind.lifetime,
          expiresAt: null,
          inTrial: false,
        ),
      );
    });

    test('unknown with a cached Annual still running is Entitled', () {
      final until = now.add(const Duration(days: 30));
      expect(
        effectiveAccess(
          const AccessUnknown(),
          cached('entitled', plan: 'annual', until: until),
          now,
        ),
        Entitled(plan: PlanKind.annual, expiresAt: until, inTrial: false),
      );
    });

    test('unknown with a cached Annual ended within 16 days is Entitled', () {
      for (final ago in [const Duration(days: 1), const Duration(days: 16)]) {
        final until = now.subtract(ago);
        expect(
          effectiveAccess(
            const AccessUnknown(),
            cached('entitled', plan: 'annual', until: until),
            now,
          ),
          Entitled(plan: PlanKind.annual, expiresAt: until, inTrial: false),
          reason: '$ago ago',
        );
      }
    });

    test('unknown with a cached Annual ended over 16 days ago is Lapsed', () {
      final until = now.subtract(const Duration(days: 16, seconds: 1));
      expect(
        effectiveAccess(
          const AccessUnknown(),
          cached('entitled', plan: 'annual', until: until),
          now,
        ),
        Lapsed(plan: PlanKind.annual, endedAt: until),
      );
    });

    test('unknown with a cached lapse is Lapsed', () {
      final until = now.subtract(const Duration(days: 40));
      expect(
        effectiveAccess(
          const AccessUnknown(),
          cached('lapsed', plan: 'monthly', until: until),
          now,
        ),
        Lapsed(plan: PlanKind.monthly, endedAt: until),
      );
    });

    test('unknown with neverPaid or nothing cached stays unknown', () {
      expect(
        effectiveAccess(const AccessUnknown(), cached('neverPaid'), now),
        const AccessUnknown(),
      );
      expect(
        effectiveAccess(const AccessUnknown(), blank, now),
        const AccessUnknown(),
      );
    });

    test('unknown with an unreadable cache stays unknown', () {
      for (final settings in [
        cached('entitled', plan: 'weekly', until: now),
        cached('entitled', plan: 'annual'),
        cached('lapsed'),
        cached('paused', plan: 'annual', until: now),
      ]) {
        expect(
          effectiveAccess(const AccessUnknown(), settings, now),
          const AccessUnknown(),
        );
      }
    });
  });

  group('withCachedAccess', () {
    test('unknown leaves the settings unchanged', () {
      final settings = cached('lapsed', plan: 'monthly', until: now);
      expect(withCachedAccess(settings, const AccessUnknown()), settings);
    });

    test('keeps every other setting', () {
      final saved = withCachedAccess(blank, const NeverPaid());
      expect(saved.userName, 'Sam');
      expect(saved.accessState, 'neverPaid');
      expect(saved.accessPlan, isNull);
      expect(saved.accessUntil, isNull);
    });

    test('round-trips Entitled', () {
      final until = now.add(const Duration(days: 300));
      final live = Entitled(
        plan: PlanKind.annual,
        expiresAt: until,
        inTrial: false,
      );
      final saved = withCachedAccess(blank, live);
      expect(saved, cached('entitled', plan: 'annual', until: until));
      expect(effectiveAccess(const AccessUnknown(), saved, now), live);
    });

    test('round-trips Lapsed', () {
      final live = Lapsed(
        plan: PlanKind.monthly,
        endedAt: now.subtract(const Duration(days: 3)),
      );
      final saved = withCachedAccess(blank, live);
      expect(effectiveAccess(const AccessUnknown(), saved, now), live);
    });

    test('round-trips NeverPaid as a cleared plan', () {
      final saved = withCachedAccess(
        cached('lapsed', plan: 'monthly', until: now),
        const NeverPaid(),
      );
      expect(saved, cached('neverPaid'));
      expect(
        effectiveAccess(const AccessUnknown(), saved, now),
        const AccessUnknown(),
      );
    });
  });

  test('the grace period is 16 days', () {
    expect(accessGrace, const Duration(days: 16));
  });
}
