import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/app/shell/app_shell.dart';
import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/features/design_system/presentation/design_system_page.dart';
import 'package:exhale/features/home/presentation/pages/habit_details_page.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/habit_picker_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/setup_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    observers: [shellRouteObserver],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const HabitPickerPage(),
        routes: [
          GoRoute(path: 'plan', builder: (context, state) => const SetupPage()),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.designSystem,
        builder: (context, state) => const DesignSystemPage(),
      ),
      GoRoute(
        path: AppRoutes.habit,
        builder: (context, state) => HabitDetailsPage(
          habitId: int.parse(state.pathParameters['habitId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.editPlan,
        builder: (context, state) =>
            EditPlanPage(habitId: int.parse(state.pathParameters['habitId']!)),
      ),
      GoRoute(
        path: AppRoutes.logs,
        builder: (context, state) =>
            LogsPage(query: LogsQuery.fromUri(state.uri)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
