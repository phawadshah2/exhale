import 'package:exhale/features/paywall/data/storekit/store_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  Object? answer;

  setUp(() {
    calls.clear();
    answer = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('exhale/store'), (
          call,
        ) async {
          calls.add(call);
          return answer;
        });
  });

  test('requestRefund sends the product id', () async {
    answer = 'requested';

    expect(await const StoreChannel().requestRefund('p'), 'requested');
    expect(calls.single.method, 'requestRefund');
    expect(calls.single.arguments, {'productId': 'p'});
  });

  test('renewingSubscription returns the map or null', () async {
    expect(await const StoreChannel().renewingSubscription(), isNull);

    answer = {'productId': 'p', 'renewsAt': '2026-12-03T09:00:00.000Z'};
    expect(await const StoreChannel().renewingSubscription(), {
      'productId': 'p',
      'renewsAt': '2026-12-03T09:00:00.000Z',
    });
    expect(calls.last.method, 'renewingSubscription');
  });
}
