import 'package:exhale/features/habit/domain/entities/habit.dart';

/// Every line of onboarding copy.
abstract final class OnboardingCopy {
  static const splashLine = 'We need to talk.';

  // Welcome.
  static const welcomeSender = 'You · Tonight 11:48 PM';
  static const excuses = [
    'just one more',
    "it's basically flavoured air",
    "I'll quit properly on Monday",
  ];
  static const welcomeRead = 'Read 11:49 PM';
  static const List<String> welcomeReplies = [
    'Heard them all. Twice.',
    _welcomeOffer,
  ];
  static const _welcomeOffer =
      'How about a limit that gets a little smaller every day, until it hits '
      'zero?';
  static const welcomeTitle = 'Stop negotiating with your cravings.';
  static const welcomeBody =
      "They're not your business partner. One tap to log, a limit that "
      'drops every day, and nothing leaves your phone.';
  static const welcomeButton = 'Make a plan';
  static const welcomeFinePrint = 'A behaviour tool, not medical advice.';

  // Habit.
  static const habitPrompt = "Let's start with the obvious.";
  static const habitTitle = 'What are we quitting?';
  static const habitLead = 'Pick the main one. You can add another later.';
  static const somethingElse = 'Something else';
  static const customNameLabel = 'Habit';
  static const customNameHint = 'Gaming';
  static const customUnitLabel = 'One log is a…';
  static const customUnitHint = 'game';

  static String habitReply(HabitKind kind) => switch (kind) {
    HabitKind.vaping => 'Ah. The USB stick you inhale.',
    HabitKind.smoking => 'Classic. Retro, even.',
    HabitKind.nicotinePouches => 'Discreet. Your gums disagree.',
    HabitKind.alcohol => 'Cutting down, not cancelling weekends.',
    HabitKind.caffeine => 'Bold. Good luck with Mondays.',
    HabitKind.energyDrinks => 'Your heart would like a word.',
    HabitKind.junkFood => 'Fries are not a personality.',
    HabitKind.socialMedia => 'Doomscrolling, meet your limit.',
    HabitKind.custom => 'Mysterious. We respect it.',
  };

  // Daily amount.
  static const amountPrompt =
      "Be honest. I can't help with a number you made up.";
  static String amountTitle(String units) => 'How many $units on a normal day?';
  static String perDay(String units) => '$units a day';
  static const fewer = 'Fewer';
  static const more = 'More';
  static String dotCaption(int unit, String units) =>
      'Each dot is $unit $units';

  /// By share of the habit's usual daily amount ([typical]).
  static String amountReaction({required int amount, required int typical}) {
    final share = amount / typical;
    if (share < 0.5) return 'Practically a hobby.';
    if (share <= 1) return 'Respectable. For now.';
    if (share <= 2) return "That's not a habit. That's a part-time job.";
    return "That's a full-time job with overtime.";
  }

  // Cost.
  static const costPrompt = 'Now the painful bit.';
  static String costTitleContainer(String container) =>
      'What does a $container cost?';
  static String costTitleUnit(String unit) => 'What does one $unit cost?';
  static String priceOf(String thing) => 'Price of one $thing';
  static String perContainer(String units, String container) =>
      '${units[0].toUpperCase()}${units.substring(1)} per $container';
  static const currency = 'Currency';
  static const perContainerHint = "Check the box. Or guess, we won't tell.";
  static const aMonth = 'A month';
  static const aYear = 'A year';
  static const costReply = 'Your rent is jealous.';
  static const skipPrice = "I'd rather not know";
  static const invalidPrice = 'Enter a valid price, or leave it empty.';

  // Your day.
  static const dayPrompt =
      "When are you awake? I'll spread your limit across it.";
  static const dayTitle = 'When does your day run?';
  static String awakeDuration(int minutes) {
    final rest = minutes % 60;
    return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
  }

  static const awake = 'awake';
  static const wakeUp = 'Wake up';
  static const bedtime = 'Bedtime';
  static const dayNote = 'Used to pace your limit. Never to lock you out.';

  // The deal.
  static const dealPrompt = "Here's the deal.";
  static String dealTitle(int amount, String date) =>
      '$amount today. Zero by $date.';
  static const pick = 'Pick';
  static const tomorrow = 'Tomorrow';
  static const quitIn = 'Quit in';
  static const backAYear = 'Back a year';
  static String paceLine(int minutes) =>
      "Today that's about one every $minutes min. It gets slower from here.";
  static const dealButton = 'Shake on it';
  static const dealFinePrint = 'Change the plan any time in Settings.';

  static const continueButton = 'Continue';
}
