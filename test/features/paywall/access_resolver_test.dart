import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/store_transaction.dart';
import 'package:exhale/features/paywall/domain/services/access_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bought = DateTime.utc(2026, 11, 3);

  StoreTransaction tx(PlanKind plan, {DateTime? at, Duration? length}) {
    final purchasedAt = at ?? bought;
    return StoreTransaction(
      plan: plan,
      purchasedAt: purchasedAt,
      expiresAt: length == null ? null : purchasedAt.add(length),
    );
  }

  group('PlanKind', () {
    test('maps to and from product ids', () {
      expect(PlanKind.annual.productId, 'com.phawadshah.exhale.annual');
      expect(PlanKind.monthly.productId, 'com.phawadshah.exhale.monthly');
      expect(PlanKind.lifetime.productId, 'com.phawadshah.exhale.lifetime');
      for (final plan in PlanKind.values) {
        expect(PlanKind.ofProductId(plan.productId), plan);
      }
      expect(PlanKind.ofProductId('com.other.app.annual'), isNull);
    });
  });

  group('resolveAccess', () {
    test('a current monthly transaction is Entitled', () {
      final monthly = tx(PlanKind.monthly, length: const Duration(days: 30));
      expect(
        resolveAccess(current: [monthly], history: [monthly]),
        Entitled(
          plan: PlanKind.monthly,
          expiresAt: monthly.expiresAt,
          inTrial: false,
        ),
      );
    });

    test('Lifetime wins over Annual and Monthly', () {
      final access = resolveAccess(
        current: [
          tx(PlanKind.monthly, length: const Duration(days: 30)),
          tx(PlanKind.lifetime),
          tx(PlanKind.annual, length: const Duration(days: 365)),
        ],
        history: const [],
      );
      expect(
        access,
        const Entitled(
          plan: PlanKind.lifetime,
          expiresAt: null,
          inTrial: false,
        ),
      );
    });

    test('Annual wins over Monthly', () {
      final annual = tx(PlanKind.annual, length: const Duration(days: 365));
      final access = resolveAccess(
        current: [
          tx(PlanKind.monthly, length: const Duration(days: 30)),
          annual,
        ],
        history: const [],
      );
      expect((access as Entitled).plan, PlanKind.annual);
      expect(access.expiresAt, annual.expiresAt);
    });

    test('Annual of 8 days or less is in the trial', () {
      for (final days in [7, 8]) {
        final access = resolveAccess(
          current: [tx(PlanKind.annual, length: Duration(days: days))],
          history: const [],
        );
        expect((access as Entitled).inTrial, isTrue, reason: '$days days');
      }
    });

    test('Annual longer than 8 days is not in the trial', () {
      final access = resolveAccess(
        current: [
          tx(PlanKind.annual, length: const Duration(days: 8, minutes: 1)),
        ],
        history: const [],
      );
      expect((access as Entitled).inTrial, isFalse);
    });

    test('a short Monthly is never in the trial', () {
      final access = resolveAccess(
        current: [tx(PlanKind.monthly, length: const Duration(days: 7))],
        history: const [],
      );
      expect((access as Entitled).inTrial, isFalse);
    });

    test('no current but history is Lapsed of the newest purchase', () {
      final older = tx(
        PlanKind.monthly,
        at: DateTime.utc(2026, 9, 3),
        length: const Duration(days: 30),
      );
      final newer = tx(
        PlanKind.annual,
        at: DateTime.utc(2026, 10, 3),
        length: const Duration(days: 7),
      );
      expect(
        resolveAccess(current: const [], history: [newer, older]),
        Lapsed(plan: PlanKind.annual, endedAt: newer.expiresAt),
      );
      expect(
        resolveAccess(current: const [], history: [older, newer]),
        Lapsed(plan: PlanKind.annual, endedAt: newer.expiresAt),
      );
    });

    test('a lapsed Lifetime (refunded) has no end date', () {
      expect(
        resolveAccess(current: const [], history: [tx(PlanKind.lifetime)]),
        const Lapsed(plan: PlanKind.lifetime, endedAt: null),
      );
    });

    test('nothing at all is NeverPaid', () {
      expect(
        resolveAccess(current: const [], history: const []),
        const NeverPaid(),
      );
    });
  });

  group('value equality', () {
    test('StoreTransaction', () {
      expect(
        tx(PlanKind.annual, length: const Duration(days: 7)),
        tx(PlanKind.annual, length: const Duration(days: 7)),
      );
      expect(
        tx(PlanKind.annual, length: const Duration(days: 7)),
        isNot(tx(PlanKind.annual, length: const Duration(days: 8))),
      );
      expect(tx(PlanKind.annual).hashCode, tx(PlanKind.annual).hashCode);
    });

    test('Entitled', () {
      final a = Entitled(
        plan: PlanKind.annual,
        expiresAt: bought,
        inTrial: true,
      );
      expect(
        a,
        Entitled(plan: PlanKind.annual, expiresAt: bought, inTrial: true),
      );
      expect(
        a.hashCode,
        Entitled(
          plan: PlanKind.annual,
          expiresAt: bought,
          inTrial: true,
        ).hashCode,
      );
      expect(
        a,
        isNot(
          Entitled(plan: PlanKind.annual, expiresAt: bought, inTrial: false),
        ),
      );
      expect(
        a,
        isNot(
          Entitled(plan: PlanKind.monthly, expiresAt: bought, inTrial: true),
        ),
      );
    });

    test('Lapsed', () {
      expect(
        Lapsed(plan: PlanKind.monthly, endedAt: bought),
        Lapsed(plan: PlanKind.monthly, endedAt: bought),
      );
      expect(
        Lapsed(plan: PlanKind.monthly, endedAt: bought).hashCode,
        Lapsed(plan: PlanKind.monthly, endedAt: bought).hashCode,
      );
      expect(
        Lapsed(plan: PlanKind.monthly, endedAt: bought),
        isNot(const Lapsed(plan: PlanKind.monthly, endedAt: null)),
      );
    });

    test('NeverPaid and AccessUnknown', () {
      expect(const NeverPaid(), const NeverPaid());
      expect(const NeverPaid().hashCode, const NeverPaid().hashCode);
      expect(const AccessUnknown(), const AccessUnknown());
      expect(const AccessUnknown().hashCode, const AccessUnknown().hashCode);
      expect(const NeverPaid(), isNot(const AccessUnknown()));
    });
  });
}
