abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const addHabit = '/add-habit';
  static const home = '/home';
  static const habit = '/habit/:habitId';
  static const editPlan = '/habit/:habitId/plan';

  static String habitFor(int habitId) => '/habit/$habitId';
  static String editPlanFor(int habitId) => '/habit/$habitId/plan';
  static const logs = '/logs';
  static const settings = '/settings';
  static const designSystem = '/design-system';
}
