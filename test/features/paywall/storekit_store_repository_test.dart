import 'dart:async';

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/data/repositories/storekit_store_repository.dart';
import 'package:exhale/features/paywall/data/storekit/storekit_gateway.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

SK2Product _product(
  PlanKind plan,
  double price,
  String displayPrice, {
  String code = 'USD',
  String symbol = r'$',
}) => SK2Product(
  id: plan.productId,
  displayName: plan.name,
  description: '',
  price: price,
  displayPrice: displayPrice,
  type: plan == PlanKind.lifetime
      ? SK2ProductType.nonConsumable
      : SK2ProductType.autoRenewable,
  priceLocale: SK2PriceLocale(currencyCode: code, currencySymbol: symbol),
);

SK2Transaction _transaction(
  String productId, {
  required DateTime purchased,
  DateTime? expires,
  String id = '1',
}) => SK2Transaction(
  id: id,
  originalId: id,
  productId: productId,
  purchaseDate: '${purchased.millisecondsSinceEpoch}',
  expirationDate: expires == null ? null : '${expires.millisecondsSinceEpoch}',
  appAccountToken: null,
);

class _FakeGateway implements StoreKitGateway {
  List<SK2Product> productList = [
    _product(PlanKind.annual, 34.99, r'$34.99'),
    _product(PlanKind.monthly, 7.99, r'$7.99'),
    _product(PlanKind.lifetime, 59.99, r'$59.99'),
  ];
  Map<String, bool> introEligible = {};
  SK2ProductPurchaseResult purchaseResult = SK2ProductPurchaseResult.success;
  List<SK2Transaction> current = [];
  List<SK2Transaction> all = [];
  List<SK2Transaction> unfinishedList = [];
  final List<int> finished = [];
  final List<String> introChecks = [];
  final List<String> purchased = [];
  int syncCalls = 0;
  int manageCalls = 0;
  Exception? error;
  Completer<void>? hang;
  final StreamController<void> updateController = StreamController.broadcast();

  Future<T> _answer<T>(T value) async {
    if (hang != null) await hang!.future;
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<List<SK2Product>> products(List<String> ids) =>
      _answer(productList.where((p) => ids.contains(p.id)).toList());

  @override
  Future<bool> isIntroEligible(String productId) {
    introChecks.add(productId);
    return _answer(introEligible[productId] ?? false);
  }

  @override
  Future<SK2ProductPurchaseResult> purchase(String productId) {
    purchased.add(productId);
    return _answer(purchaseResult);
  }

  @override
  Future<List<SK2Transaction>> currentEntitlements() => _answer(current);

  @override
  Future<List<SK2Transaction>> transactions() => _answer(all);

  @override
  Future<List<SK2Transaction>> unfinished() => _answer(unfinishedList);

  @override
  Future<void> finish(int id) async => finished.add(id);

  @override
  Future<void> sync() {
    syncCalls++;
    return _answer(null);
  }

  @override
  Future<void> showManageSubscriptions() {
    manageCalls++;
    return _answer(null);
  }

  @override
  Stream<void> get updates => updateController.stream;
}

const _quickTimeout = Duration(milliseconds: 50);

T _value<T>(Result<T> result) => (result as Success<T>).value;

void _expectStoreFailure(Result<Object?> result) =>
    expect((result as FailureResult).failure, isA<StoreFailure>());

void main() {
  late _FakeGateway gateway;
  late StoreKitStoreRepository repository;
  late StoreKitStoreRepository quick;

  setUp(() {
    gateway = _FakeGateway();
    repository = StoreKitStoreRepository(gateway);
    quick = StoreKitStoreRepository(gateway, timeout: _quickTimeout);
  });

  test('the store timeout is 10 s', () {
    expect(StoreKitStoreRepository.defaultTimeout, const Duration(seconds: 10));
  });

  group('loadOffers', () {
    test('three products become three offers, in paywall order', () async {
      gateway
        ..productList = gateway.productList.reversed.toList()
        ..introEligible = {PlanKind.annual.productId: true};

      expect(_value(await repository.loadOffers()), const [
        Offer(
          plan: PlanKind.annual,
          displayPrice: r'$34.99',
          price: 34.99,
          currencyCode: 'USD',
          currencySymbol: r'$',
          trialEligible: true,
        ),
        Offer(
          plan: PlanKind.monthly,
          displayPrice: r'$7.99',
          price: 7.99,
          currencyCode: 'USD',
          currencySymbol: r'$',
          trialEligible: false,
        ),
        Offer(
          plan: PlanKind.lifetime,
          displayPrice: r'$59.99',
          price: 59.99,
          currencyCode: 'USD',
          currencySymbol: r'$',
          trialEligible: false,
        ),
      ]);
    });

    test('trial eligibility is asked only for Annual', () async {
      gateway.introEligible = {
        PlanKind.monthly.productId: true,
        PlanKind.lifetime.productId: true,
      };

      final offers = _value(await repository.loadOffers());

      expect(offers.map((o) => o.trialEligible), [false, false, false]);
      expect(gateway.introChecks, [PlanKind.annual.productId]);
    });

    test('keeps the storefront currency', () async {
      gateway.productList = [
        for (final plan in PlanKind.values)
          _product(plan, 129, 'AED 129.00', code: 'AED', symbol: 'AED'),
      ];

      final offers = _value(await repository.loadOffers());

      expect(offers.first.currencyCode, 'AED');
      expect(offers.first.currencySymbol, 'AED');
      expect(offers.first.displayPrice, 'AED 129.00');
    });

    test('fewer than three products is a store failure', () async {
      gateway.productList = gateway.productList.take(2).toList();

      _expectStoreFailure(await repository.loadOffers());
    });

    test('a platform error is a store failure', () async {
      gateway.error = PlatformException(code: 'storekit_no_response');

      _expectStoreFailure(await repository.loadOffers());
    });

    test('no answer in time is a store failure', () async {
      gateway.hang = Completer();

      _expectStoreFailure(await quick.loadOffers());
    });
  });

  group('currentAccess', () {
    final bought = DateTime(2026, 11, 3, 9);

    test('maps current entitlements into access', () async {
      final expires = bought.add(const Duration(days: 7));
      gateway
        ..current = [
          _transaction(
            PlanKind.annual.productId,
            purchased: bought,
            expires: expires,
          ),
        ]
        ..all = gateway.current;

      expect(
        _value(await repository.currentAccess()),
        Entitled(plan: PlanKind.annual, expiresAt: expires, inTrial: true),
      );
    });

    test('history without a current entitlement is Lapsed', () async {
      final expires = bought.add(const Duration(days: 30));
      gateway.all = [
        _transaction(
          PlanKind.monthly.productId,
          purchased: bought,
          expires: expires,
        ),
      ];

      expect(
        _value(await repository.currentAccess()),
        Lapsed(plan: PlanKind.monthly, endedAt: expires),
      );
    });

    test('ignores products that are not ours', () async {
      gateway
        ..current = [_transaction('com.other.app.pro', purchased: bought)]
        ..all = gateway.current;

      expect(_value(await repository.currentAccess()), const NeverPaid());
    });

    test('a platform error is a store failure', () async {
      gateway.error = PlatformException(code: 'storekit2_failed');

      _expectStoreFailure(await repository.currentAccess());
    });

    test('no answer in time is a store failure', () async {
      gateway.hang = Completer();

      _expectStoreFailure(await quick.currentAccess());
    });
  });

  group('purchase', () {
    test('success finishes every unfinished transaction', () async {
      gateway.unfinishedList = [
        _transaction(
          PlanKind.annual.productId,
          purchased: DateTime(2026, 11, 3),
          id: '41',
        ),
        _transaction(
          PlanKind.monthly.productId,
          purchased: DateTime(2026, 11, 2),
          id: '42',
        ),
      ];

      expect(
        _value(await repository.purchase(PlanKind.annual)),
        PurchaseOutcome.purchased,
      );
      expect(gateway.purchased, [PlanKind.annual.productId]);
      expect(gateway.finished, [41, 42]);
    });

    test('a cancel is cancelled and finishes nothing', () async {
      gateway
        ..purchaseResult = SK2ProductPurchaseResult.userCancelled
        ..unfinishedList = [
          _transaction(
            PlanKind.annual.productId,
            purchased: DateTime(2026, 11, 3),
          ),
        ];

      expect(
        _value(await repository.purchase(PlanKind.monthly)),
        PurchaseOutcome.cancelled,
      );
      expect(gateway.finished, isEmpty);
    });

    test('pending is pending', () async {
      gateway.purchaseResult = SK2ProductPurchaseResult.pending;

      expect(
        _value(await repository.purchase(PlanKind.lifetime)),
        PurchaseOutcome.pending,
      );
    });

    test('unverified is a store failure', () async {
      gateway.purchaseResult = SK2ProductPurchaseResult.unverified;

      _expectStoreFailure(await repository.purchase(PlanKind.annual));
    });

    test('a platform error is a store failure', () async {
      gateway.error = PlatformException(code: 'storekit2_purchase_failed');

      _expectStoreFailure(await repository.purchase(PlanKind.annual));
    });

    test('waits for the buyer past the store timeout', () async {
      gateway.hang = Completer();
      Result<PurchaseOutcome>? result;
      unawaited(quick.purchase(PlanKind.annual).then((r) => result = r));

      await Future<void>.delayed(_quickTimeout * 4);
      expect(result, isNull);
      gateway.hang!.complete();
      await pumpEventQueue();
      expect(_value(result!), PurchaseOutcome.purchased);
    });

    test('restore and manage also wait past the store timeout', () async {
      gateway.hang = Completer();
      final restore = quick.restore();
      final manage = quick.manageSubscriptions();

      await Future<void>.delayed(_quickTimeout * 4);
      gateway.hang!.complete();
      expect(await restore, isA<Success<void>>());
      expect(await manage, isA<Success<void>>());
    });
  });

  group('restore and manage', () {
    test('restore syncs with the App Store', () async {
      expect(await repository.restore(), isA<Success<void>>());
      expect(gateway.syncCalls, 1);
    });

    test('a failed restore is a store failure', () async {
      gateway.error = PlatformException(code: 'storekit2_sync_failed');

      _expectStoreFailure(await repository.restore());
    });

    test('manage shows the subscriptions sheet', () async {
      expect(await repository.manageSubscriptions(), isA<Success<void>>());
      expect(gateway.manageCalls, 1);
    });
  });

  group('changes', () {
    test(
      'an update finishes every unfinished transaction, then emits',
      () async {
        gateway.unfinishedList = [
          _transaction(
            PlanKind.annual.productId,
            purchased: DateTime(2026, 11, 3),
            id: '7',
          ),
        ];
        var emitted = 0;
        final finishedWhenEmitted = <int>[];
        final subscription = repository.changes.listen((_) {
          emitted++;
          finishedWhenEmitted.addAll(gateway.finished);
        });
        addTearDown(subscription.cancel);

        gateway.updateController.add(null);
        await pumpEventQueue();

        expect(emitted, 1);
        expect(finishedWhenEmitted, [7]);
      },
    );

    test('still emits when finishing fails', () async {
      gateway.error = PlatformException(code: 'storekit2_failed');
      var emitted = 0;
      final subscription = repository.changes.listen((_) => emitted++);
      addTearDown(subscription.cancel);

      gateway.updateController.add(null);
      await pumpEventQueue();

      expect(emitted, 1);
    });
  });
}
