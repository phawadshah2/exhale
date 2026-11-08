import 'package:exhale/features/habit/domain/entities/habit.dart';

/// Every line of onboarding copy.
abstract final class OnboardingCopy {
  static const splashLine = 'We need to talk.';

  // Welcome.
  static const excuses = [
    'just one more',
    "it's basically flavoured air",
    "I'll quit properly on Monday",
  ];
  static const brand = 'EXHALE';
  static const welcomeTitle = 'Stop negotiating with your cravings.';
  static const welcomeNegotiating = 'negotiating';
  static const welcomeBody =
      "They're not your business partner. We'll handle them with a limit "
      'that shrinks to zero.';
  static const welcomeButton = "Let's talk";
  static const welcomeFinePrint = 'A behaviour tool, not medical advice.';
  static const List<(String, String)> welcomeRows = [
    (
      'One tap to log',
      'Every time, even over the limit. Honest beats perfect.',
    ),
    (
      'A limit that steps down',
      'One fewer at a time, until it hits zero on a date you pick.',
    ),
    (
      'Bad weeks hold, never reset',
      'Slip up and the step waits. You never start over.',
    ),
    ('Just you and your phone', 'No account. Nothing you log leaves it.'),
  ];

  // Chat.
  static const chatName = 'Exhale';
  static const chatIdle = 'here to help. Unfortunately.';
  static const chatTyping = 'typing…';
  static const chatSeePlan = 'See my plan';
  static const chatSender = 'You';
  static String chatSentAt(String time) => ' · $time';
  static const sent = 'Sent';
  static const read = 'Read';
  static String status(String state, String time) => '$state $time';
  static const jumpToNewest = 'Jump to the newest message';
  static const changeHint = 'Double tap to change.';
  static const sendName = 'Send your name';
  static const sendHabit = 'Send your habit';
  static const cardName = 'Your name';
  static const cardHabit = 'What are we quitting?';
  static const cardAmount = 'Times a day';
  static String cardPrice(String? container) =>
      container == null ? 'Price of one' : 'Price of a $container';
  static String cardPerPod(String units, String container) =>
      perContainer(units, container);
  static const cardDay = 'Your day';
  static const sendPrice = 'Send your price';
  static const priceHint = '0.00';
  static const fiveFewer = '5 fewer';
  static const fiveMore = '5 more';
  static const upAt = 'Up at';
  static const lightsOutAt = 'Lights out';
  static const wakeEarlier = 'Wake up 30 minutes earlier';
  static const wakeLater = 'Wake up 30 minutes later';
  static const bedEarlier = 'Lights out 30 minutes earlier';
  static const bedLater = 'Lights out 30 minutes later';

  /// 45 min, 1 h, 1 h 20 min.
  static String span(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest min';
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  static const askWho =
      'Before you send me another excuse: who am I talking to?';
  static const nameHint = 'Your first name';
  static const send = 'Send';
  static const nameSkip = "I'd rather not say";
  static String nameReply(String name) =>
      '$name. Lovely name. Shame about the excuses.';
  static const nameSkipReply = "A mystery. Your excuses weren't.";
  static const heardThemAll = 'Heard them all, by the way. Twice.';
  static const helpingIsMyJob =
      "Lucky for you, helping is my whole job. Let's start with the obvious. "
      'What are we quitting?';
  static String amountAsk(String verb) =>
      'Be honest. How many times a day do you $verb? A real number. Not a '
      'Monday one.';
  static String amountAnswer(int n) => '$n a day';
  static String painfulAsk(String? container) {
    final question = container == null
        ? 'What does one cost you, roughly?'
        : 'What does a $container cost you?';
    return ' Now the painful bit. $question';
  }

  static String perContainerAsk(String units, String container) =>
      'And how many $units does one $container last? Ballpark is fine. '
      "I'm not your accountant.";
  static String perContainerAnswer(int per, String container) =>
      '$per a $container';

  /// How long one container lasts at [amount] a day, to the nearest half day.
  static String perPodCaption({
    required int per,
    required int amount,
    required String container,
  }) {
    final halves = (per / amount * 2).round();
    if (halves <= 2) return 'About one $container every day';
    final whole = halves ~/ 2;
    final days = halves.isOdd ? '$whole½' : '$whole';
    return 'About one $container every $days days';
  }

  static const other = 'Other';
  static const aboutRight = "That's about right";
  static const thatsMyDay = "That's my day";
  static const customHabitAsk = 'What is it?';
  static const backToList = 'Back to the list';
  static const regionNote = 'from your region';
  static const change = 'Change';
  static String noPriceReply(String reaction) =>
      '$reaction No price tag on this one. Just your time, which is worse.';
  static String skipPriceReply(String units) =>
      "Ignorance is bliss. Expensive bliss. I'll count $units instead. Add a "
      "price whenever you're brave.";
  static const moneyCardTitle = 'YOUR NEXT 12 MONTHS';
  static const asItIs = 'As it is';
  static const withPlan = 'With the plan';
  static const youKeep = 'You keep ';
  static const dayTwoMore = 'Two more, then your plan.';
  static String daySpread(int amount) =>
      "I'll spread your $amount so they don't all land before lunch. When "
      "does your day start, and when's lights out? Roughly. I won't check.";
  static String dayAnswer(String wake, String bed) => '$wake to $bed';
  static String dayCardLine(String awake, String gap) =>
      '$awake awake · one every $gap';
  static String planReady(String name) =>
      "That's everything${name.isEmpty ? '' : ', $name'}. Your plan's ready. "
      'Brace yourself.';

  // The tagline under "See my plan", after each answer.
  static const taglineStart = 'Nothing you type leaves your phone.';
  static const taglineExcuses = 'Three excuses before hello. Bold opener.';
  static String taglineName(String name) =>
      'Nice to meet you, $name. Your excuses already have.';
  static const taglineNameSkipped = 'Fine. Your excuses introduced themselves.';
  static String taglineHabit(HabitKind kind) => switch (kind) {
    HabitKind.vaping => 'Vaping. Flavoured air with a monthly bill.',
    HabitKind.smoking => 'Smoking. A classic with a cough.',
    HabitKind.nicotinePouches => 'Pouches. Discreet, not free.',
    HabitKind.caffeine => 'Caffeine. Borrowed energy, paid back at 3 PM.',
    HabitKind.energyDrinks => 'Energy drinks. Rent for your heartbeat.',
    HabitKind.alcohol => 'Alcohol. The weekend wants a word.',
    HabitKind.junkFood => 'Junk food. Snacks are not a personality.',
    HabitKind.socialMedia => "Social media. Hours you'll never get back.",
    HabitKind.custom => 'Something else. Mysterious. Expensive, probably.',
  };
  static String taglineAmount(int n, HabitKind kind) => switch (kind) {
    HabitKind.vaping ||
    HabitKind.smoking ||
    HabitKind.nicotinePouches => '$n a day. Your lungs have filed a complaint.',
    _ => '$n a day. Noted. Judged, slightly.',
  };
  static String taglinePrice(String price, String? container) =>
      '$price ${container == null ? 'each' : 'a $container'}. '
      'Your wallet felt that.';
  static const taglinePriceSkipped = 'Not knowing is still paying.';
  static String taglineYear(String perYear, HabitKind kind) => switch (kind) {
    HabitKind.vaping ||
    HabitKind.smoking => "$perYear a year. That's a holiday you inhaled.",
    _ => "$perYear a year. That's a holiday you spent on this.",
  };
  static const taglineDay = "Plan's ready. No more Mondays.";

  // Habit.
  static const habitPrompt = "Let's start with the obvious.";
  static const habitTitle = 'What are we quitting?';
  static const habitLead = 'Pick the main one.';
  static const changeHabitPrompt = 'New target? We can take it.';
  static const changeHabitTitle = 'Change habit';
  static String changeHabitLead(String current) =>
      'It takes the place of $current, with its own plan and limits.';
  static const tracking = 'TRACKING';
  static String replaceTitle(String current, String next) =>
      'Replace $current with $next?';
  static String replaceMessage(String current, String next) =>
      "Your $current logs stay saved but won't show while you track $next. "
      'Your plan and history start fresh.';
  static const replaceConfirm = 'Replace';
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

  // Your day (the day window picker in Settings).
  static String awakeDuration(int minutes) {
    final rest = minutes % 60;
    return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
  }

  static const awake = 'awake';
  static const hourUnit = 'h';
  static const minuteUnit = 'min';
  static const wakeUp = 'Wake up';
  static const bedtime = 'Bedtime';

  // The deal.
  static const dealPrompt = "Here's the deal.";
  static String dealTitle(int amount, String date) =>
      '$amount today. Zero by $date.';
  static const pick = 'Pick';
  static const quitDate = 'Quit date';
  static const steepWarning =
      "That's more than one fewer a day. A later date may feel easier.";
  static const tomorrow = 'Tomorrow';
  static const quitIn = 'Quit in';
  static String days(int count) => count == 1 ? '1 day' : '$count days';
  static const backAYear = 'Back a year';
  static String paceLine(int minutes) =>
      "Today that's about one every $minutes min. It gets slower from here.";
  static const dealButton = 'Shake on it';
  static String dealEyebrow(int amount) => '$amount today. Three ways to zero.';
  static const dealHeadline = 'How fast do you want to go?';
  static const suggested = 'SUGGESTED';
  static String weeks(int n) => '$n weeks';
  static String dealGo(String? pace, String date) =>
      '${pace == null ? 'Go' : 'Go ${pace.toLowerCase()}'} · zero by $date';
  static const pickOwnDate = 'Pick my own date';
  static const customPace = 'Your date';

  /// "4 weeks", or "5 wk 5 d" when it is not whole weeks.
  static String planLength(int days) => days % 7 == 0
      ? weeks(days ~/ 7)
      : days < 7
      ? '$days d'
      : '${days ~/ 7} wk ${days % 7} d';

  /// How long a stage lasts, inside the closed card's ring.
  static String stageSpan(int shortest, int longest) =>
      shortest == longest ? '${shortest}d' : '$shortest–${longest}d';
  static String stagesLine(int count, int shortest, int longest) {
    final days = shortest == longest ? '$shortest' : '$shortest–$longest';
    return '$count stages, $days ${longest == 1 ? 'day' : 'days'} each';
  }

  /// Under the grid: what a square is, by its length in days.
  static String gridNote(int squareDays) => switch (squareDays) {
    1 =>
      "Each square is a day; its number is that day's limit. Today is "
          'outlined.',
    7 =>
      'Each square is a week; its number is the daily limit when it '
          'starts. This week is outlined.',
    _ =>
      'Each square is ${squareDays ~/ 7} weeks; its number is the daily '
          'limit when they start. The first is outlined.',
  };
  static String gridSummary(int days, int start, String date) =>
      '$days days, $start a day falling to zero by $date.';
  static const dealFinePrint = 'Change the plan any time from Home.';

  static const continueButton = 'Continue';
}
