import 'package:exhale/features/paywall/data/repositories/storekit_store_repository.dart';
import 'package:exhale/features/paywall/data/storekit/storekit_gateway.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:get_it/get_it.dart';

/// [store] replaces the App Store (tests and debug walks).
void initPaywallDependencies(GetIt getIt, StoreRepository? store) {
  getIt.registerLazySingleton<StoreRepository>(
    () => store ?? StoreKitStoreRepository(const PluginStoreKitGateway()),
  );
}
