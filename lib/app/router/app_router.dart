import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/app/shell/app_shell.dart';
import 'package:exhale/app/shell/branch_fade.dart';
import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/pages/habit_details_page.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/change_habit_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/plan/presentation/pages/plan_details_page.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/widgets.dart';
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
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 380),
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
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
        path: AppRoutes.planDetails,
        builder: (context, state) => PlanDetailsPage(
          habitId: int.parse(state.pathParameters['habitId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.changeHabit,
        redirect: (context, state) {
          final habitId = int.parse(state.pathParameters['habitId']!);
          return ref.read(habitProvider(habitId)) == null
              ? AppRoutes.home
              : null;
        },
        builder: (context, state) => ChangeHabitPage(
          habitId: int.parse(state.pathParameters['habitId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.logs,
        builder: (context, state) =>
            LogsPage(query: LogsQuery.fromUri(state.uri)),
      ),
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) =>
            BranchFade(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
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
