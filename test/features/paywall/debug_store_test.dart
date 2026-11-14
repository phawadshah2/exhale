import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/data/fake/debug_store.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Access?> accessOf(String define) async {
    final store = debugStore(define, debug: true);
    if (store == null) return null;
    return switch (await store.currentAccess()) {
      Success(:final value) => value,
      FailureResult() => const AccessUnknown(),
    };
  }

  test('neverPaid', () async {
    expect(await accessOf('neverPaid'), const NeverPaid());
    expect(debugStore('neverPaid', debug: true), isA<FakeStoreRepository>());
  });

  test('lapsed is an Annual that ended', () async {
    final access = await accessOf('lapsed');
    expect(access, isA<Lapsed>());
    final lapsed = access! as Lapsed;
    expect(lapsed.plan, PlanKind.annual);
    expect(lapsed.endedAt, isNotNull);
  });

  test('entitled is Lifetime', () async {
    expect(
      await accessOf('entitled'),
      const Entitled(plan: PlanKind.lifetime, expiresAt: null, inTrial: false),
    );
  });

  test('offline cannot reach the store', () async {
    final store = debugStore('offline', debug: true)!;
    expect(await store.loadOffers(), isA<FailureResult<List<Offer>>>());
    expect(await accessOf('offline'), const AccessUnknown());
  });

  test('an unknown value or a release build gives no store', () {
    expect(debugStore('', debug: true), isNull);
    expect(debugStore('paid', debug: true), isNull);
    expect(debugStore('neverPaid', debug: false), isNull);
  });
}
