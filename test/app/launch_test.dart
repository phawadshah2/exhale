import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/app/router/launch.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entitled = Entitled(
    plan: PlanKind.annual,
    expiresAt: null,
    inTrial: true,
  );
  final lapsed = Lapsed(plan: PlanKind.monthly, endedAt: DateTime(2026, 11));
  final notEntitled = <Access>[
    const NeverPaid(),
    lapsed,
    const AccessUnknown(),
  ];

  group('resolveLaunch', () {
    test('no plan opens onboarding, whatever the access', () {
      for (final access in [...notEntitled, entitled]) {
        for (final hasLogs in [false, true]) {
          expect(
            resolveLaunch(hasPlan: false, hasLogs: hasLogs, access: access),
            Launch.onboarding,
            reason: '$access, logs: $hasLogs',
          );
        }
      }
    });

    test('a saved plan with no logs, never paid, opens welcome back', () {
      for (final access in const [NeverPaid(), AccessUnknown()]) {
        expect(
          resolveLaunch(hasPlan: true, hasLogs: false, access: access),
          Launch.welcomeBack,
          reason: '$access',
        );
      }
    });

    test('a saved plan with logs, never paid, opens the paywall', () {
      for (final access in const [NeverPaid(), AccessUnknown()]) {
        expect(
          resolveLaunch(hasPlan: true, hasLogs: true, access: access),
          Launch.paywall,
          reason: '$access',
        );
      }
    });

    test('a saved plan and a lapsed access opens locked', () {
      for (final hasLogs in [false, true]) {
        expect(
          resolveLaunch(hasPlan: true, hasLogs: hasLogs, access: lapsed),
          Launch.locked,
        );
      }
    });

    test('a saved plan and an entitled access opens home', () {
      for (final hasLogs in [false, true]) {
        expect(
          resolveLaunch(hasPlan: true, hasLogs: hasLogs, access: entitled),
          Launch.home,
        );
      }
    });
  });

  group('accessRedirect', () {
    const gated = [
      AppRoutes.home,
      AppRoutes.settings,
      '/habit/3',
      '/habit/3/plan',
      '/habit/3/stages',
      AppRoutes.logs,
      '/change-habit/3',
    ];
    const open = [
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.welcomeBack,
    ];

    test('in-app routes go to locked when lapsed', () {
      for (final location in gated) {
        expect(
          accessRedirect(location, lapsed, hasHabit: true),
          AppRoutes.locked,
          reason: location,
        );
      }
    });

    test('in-app routes go to the paywall when never paid or unknown', () {
      for (final access in const [NeverPaid(), AccessUnknown()]) {
        for (final location in gated) {
          expect(
            accessRedirect(location, access, hasHabit: true),
            AppRoutes.paywall,
            reason: '$location, $access',
          );
        }
      }
    });

    test('in-app routes stay when entitled', () {
      for (final location in gated) {
        expect(accessRedirect(location, entitled, hasHabit: true), isNull);
      }
    });

    test('the paywall and locked go home when entitled with a habit', () {
      for (final location in [AppRoutes.paywall, AppRoutes.locked]) {
        expect(
          accessRedirect(location, entitled, hasHabit: true),
          AppRoutes.home,
        );
        expect(accessRedirect(location, entitled, hasHabit: false), isNull);
        for (final access in notEntitled) {
          expect(accessRedirect(location, access, hasHabit: true), isNull);
        }
      }
    });

    test('splash, onboarding and welcome back are never redirected', () {
      for (final access in [...notEntitled, entitled]) {
        for (final location in open) {
          expect(
            accessRedirect(location, access, hasHabit: true),
            isNull,
            reason: '$location, $access',
          );
        }
      }
    });

    test('route of each launch', () {
      expect(Launch.onboarding.route, AppRoutes.onboarding);
      expect(Launch.welcomeBack.route, AppRoutes.welcomeBack);
      expect(Launch.paywall.route, AppRoutes.paywall);
      expect(Launch.locked.route, AppRoutes.locked);
      expect(Launch.home.route, AppRoutes.home);
    });
  });
}
