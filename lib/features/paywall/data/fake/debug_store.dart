import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/renewing_subscription.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';

/// The store a debug walk asks for with `--dart-define=FAKE_STORE=…`:
/// `neverPaid`, `lapsed`, `entitled` (Lifetime), `trial`, `monthly`,
/// `lifetimeRenewing` (Lifetime with Annual still renewing) or `offline`.
/// Null in a release build and for any other value, so the App Store is
/// used.
StoreRepository? debugStore(String define, {required bool debug}) {
  if (!debug) return null;
  final now = DateTime.now();
  return switch (define) {
    'neverPaid' => FakeStoreRepository(),
    'lapsed' => FakeStoreRepository(
      access: Lapsed(
        plan: PlanKind.annual,
        endedAt: now.subtract(const Duration(days: 2)),
      ),
    ),
    'entitled' => FakeStoreRepository.entitled(),
    'trial' => FakeStoreRepository(
      access: Entitled(
        plan: PlanKind.annual,
        expiresAt: now.add(const Duration(days: 2)),
        inTrial: true,
      ),
    ),
    'monthly' => FakeStoreRepository(
      access: Entitled(
        plan: PlanKind.monthly,
        expiresAt: now.add(const Duration(days: 14)),
        inTrial: false,
      ),
    ),
    'lifetimeRenewing' =>
      FakeStoreRepository.entitled()
        ..renewing = RenewingSubscription(
          plan: PlanKind.annual,
          renewsAt: now.add(const Duration(days: 20)),
        ),
    'offline' => FakeStoreRepository(offline: true),
    _ => null,
  };
}
