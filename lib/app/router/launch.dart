import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';

/// The first screen after the splash.
enum Launch {
  onboarding(AppRoutes.onboarding),
  welcomeBack(AppRoutes.welcomeBack),
  paywall(AppRoutes.paywall),
  locked(AppRoutes.locked),
  home(AppRoutes.home);

  Launch(this.route);

  final String route;
}

/// Picks the first screen from the saved plan and the access. An unknown
/// access has no usable cache by now, so it counts as never paid.
Launch resolveLaunch({
  required bool hasPlan,
  required bool hasLogs,
  required Access access,
}) {
  if (!hasPlan) return Launch.onboarding;
  return switch (access) {
    Entitled() => Launch.home,
    Lapsed() => Launch.locked,
    NeverPaid() ||
    AccessUnknown() => hasLogs ? Launch.paywall : Launch.welcomeBack,
  };
}

/// Where [location] goes for [access]; null stays. In-app routes need an
/// entitled access; the paywall and locked screen leave once it arrives.
String? accessRedirect(
  String location,
  Access access, {
  required bool hasHabit,
}) {
  if (location == AppRoutes.paywall || location == AppRoutes.locked) {
    return access is Entitled && hasHabit ? AppRoutes.home : null;
  }
  if (!_isInApp(location)) return null;
  return switch (access) {
    Entitled() => null,
    Lapsed() => AppRoutes.locked,
    NeverPaid() || AccessUnknown() => AppRoutes.paywall,
  };
}

bool _isInApp(String location) =>
    location == AppRoutes.home ||
    location == AppRoutes.settings ||
    location == AppRoutes.logs ||
    location.startsWith('/habit/') ||
    location.startsWith('/change-habit/');
