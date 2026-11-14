import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';

/// The store a debug walk asks for with `--dart-define=FAKE_STORE=…`:
/// `neverPaid`, `lapsed`, `entitled` or `offline`. Null in a release build
/// and for any other value, so the App Store is used.
StoreRepository? debugStore(String define, {required bool debug}) {
  if (!debug) return null;
  return switch (define) {
    'neverPaid' => FakeStoreRepository(),
    'lapsed' => FakeStoreRepository(
      access: Lapsed(
        plan: PlanKind.annual,
        endedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ),
    'entitled' => FakeStoreRepository.entitled(),
    'offline' => FakeStoreRepository(offline: true),
    _ => null,
  };
}
