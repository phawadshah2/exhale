abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const habit = '/habit/:habitId';
  static const editPlan = '/habit/:habitId/plan';

  static String editPlanFor(int habitId) => '/habit/$habitId/plan';
  static const planDetails = '/habit/:habitId/stages';

  static String planDetailsFor(int habitId) => '/habit/$habitId/stages';
  static const changeHabit = '/change-habit/:habitId';

  static String changeHabitFor(int habitId) => '/change-habit/$habitId';
  static const logs = '/logs';
  static const settings = '/settings';
}
