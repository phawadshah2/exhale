/// Every string on the paywall. Copy is from the spec and is not reworded.
abstract final class PaywallCopy {
  static const headlineTrial = 'Quitting is hard. Trying Exhale is free.';
  static const headlineNoTrial = "Quitting is hard. Starting isn't.";

  static String statDays(int days) => days == 1 ? '1 day' : '$days days';
  static String statSentence(String spendNoun, String period) =>
      'of $spendNoun costs more than $period.';
  static const aYear = 'a year of Exhale';
  static const aMonth = 'a month of Exhale';
  static const forGood = 'Exhale for good';

  static const today = 'Today';
  static const fullAccess = 'Full access';
  static const opensPlanStarts = 'Everything opens. Your plan starts.';
  static String opensCharged(String price) =>
      'Everything opens. $price is charged.';
  static String opensOnce(String price) => 'Everything opens. $price, once.';

  static const day5 = 'Day 5';
  static const remindBody = 'We remind you, before any charge.';
  static const remindWord = 'We remind you';
  static const day7 = 'Day 7';
  static String yearStartsBody(String price) => 'Your year starts: $price.';
  static const yearStartsWord = 'Year starts';

  static const eachYear = 'Each year';
  static const yearly = 'Yearly';
  static const eachMonth = 'Each month';
  static const monthly = 'Monthly';
  static String renewsBody(String price) =>
      'Renews at $price until you cancel.';
  static const renewsWord = 'Renews';
  static const anyTime = 'Any time';
  static const cancelKeepYear = 'Cancel in Settings, keep the year.';
  static const cancelKeepMonth = 'Cancel in Settings, keep the month.';
  static const cancelWord = 'Cancel';

  static const afterThat = 'After that';
  static const after = 'After';
  static const nothingMoreBody = 'Nothing more to pay. No renewals.';
  static const nothingWord = 'Nothing to pay';
  static const forGoodTitle = 'For good';
  static const stayingIncluded = 'Staying at zero is included.';
  static const yoursWord = 'Yours';

  static const startFreeWeek = 'Start my free week';
  static const subscribe = 'Subscribe';
  static const buyOnce = 'Buy once';
}
