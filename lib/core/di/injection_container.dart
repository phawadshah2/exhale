import 'package:get_it/get_it.dart';

/// Service locator for data sources, repositories and services.
/// Riverpod providers read their dependencies from here.
final GetIt sl = GetIt.instance;

abstract final class InjectionContainer {
  static Future<void> setupDependencies() async {
    // Feature registrations are added here as features land.
  }
}
