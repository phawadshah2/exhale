import 'package:exhale/app/router/launch.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/pages/locked_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 14, 10);

  tearDown(InjectionContainer.reset);

  Future<void> seed() => seedHabit(
    PlanDraft(
      startDay: LogicalDay(2026, 11, 1),
      startLimit: 6,
      quitDay: LogicalDay(2026, 12, 20),
    ),
  );

  /// Delivers [link] the way iOS does when a widget or activity is tapped.
  Future<void> open(WidgetTester tester, String link) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': link, 'state': null}),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('deepLinkRoute', () {
    test('maps exhale links and ignores others', () {
      expect(deepLinkRoute(Uri.parse('exhale://home')), '/home');
      expect(deepLinkRoute(Uri.parse('exhale://logs/week')), '/logs');
      expect(deepLinkRoute(Uri.parse('exhale://anything')), '/home');
      expect(deepLinkRoute(Uri.parse('/logs')), isNull);
    });
  });

  testWidgets('exhale://logs/week opens this week', (tester) async {
    await setUpTestDependencies(FixedClock(now));
    await seed();
    await tester.pumpAppPastSplash();
    expect(find.byType(HomePage), findsOneWidget);

    await open(tester, 'exhale://logs/week');

    final page = tester.widget<LogsPage>(find.byType(LogsPage));
    expect(page.query, const LogsQuery());
    await tester.disposeApp();
  });

  testWidgets('Back from a linked Logs page goes Home', (tester) async {
    await setUpTestDependencies(FixedClock(now));
    await seed();
    await tester.pumpAppPastSplash();
    await open(tester, 'exhale://logs/week');

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LogsPage), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('exhale://home opens Home', (tester) async {
    await setUpTestDependencies(FixedClock(now));
    await seed();
    await tester.pumpAppPastSplash();
    await open(tester, 'exhale://logs/week');

    await open(tester, 'exhale://home');

    expect(find.byType(HomePage), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets("a lapsed user's link lands on the locked screen", (
    tester,
  ) async {
    await setUpTestDependencies(
      FixedClock(now),
      store: FakeStoreRepository(
        access: Lapsed(plan: PlanKind.annual, endedAt: now),
        now: () => now,
      ),
    );
    await seed();
    await tester.pumpAppPastSplash();
    expect(find.byType(LockedPage), findsOneWidget);

    await open(tester, 'exhale://logs/week');

    expect(find.byType(LockedPage), findsOneWidget);
    expect(find.byType(LogsPage), findsNothing);
    await tester.disposeApp();
  });
}
