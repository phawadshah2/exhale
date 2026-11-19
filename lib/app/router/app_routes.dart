abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const habit = '/habit/:habitId';
  static const editPlan = '/habit/:habitId/plan';

  /// [focusPrice] opens the page scrolled to the price card.
  static String editPlanFor(int habitId, {bool focusPrice = false}) =>
      '/habit/$habitId/plan${focusPrice ? '?focus=price' : ''}';
  static const planDetails = '/habit/:habitId/stages';

  static String planDetailsFor(int habitId) => '/habit/$habitId/stages';
  static const changeHabit = '/change-habit/:habitId';

  static String changeHabitFor(int habitId) => '/change-habit/$habitId';
  static const logs = '/logs';
  static const settings = '/settings';
  static const paywall = '/paywall';
  static const locked = '/locked';
  static const welcomeBack = '/welcome-back';
}
