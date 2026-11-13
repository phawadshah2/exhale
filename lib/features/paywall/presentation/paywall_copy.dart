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
  static const continueLabel = 'Continue';

  static const back = 'Back';
  static const restore = 'Restore';
  static const statLabel = 'FROM YOUR ANSWERS';

  static const whatYouGet = 'WHAT YOU GET';
  static String taper(int startLimit) => 'A taper from $startLimit a day';
  static const taperValue = 'to 0';
  static const moreTime = 'More time on a hard stage';
  static const moreTimeValue = '7 days';
  static const dataLeaves = 'Data that leaves your phone';
  static const dataLeavesValue = 'Zero';

  static const annual = 'Annual';
  static const annualLine = 'Your plan + a year at zero';
  static const perYear = 'per year';
  static const monthlyName = 'Monthly';
  static const monthlyLine = 'No trial. Cancel any time.';
  static const perMonth = 'per month';
  static const lifetime = 'Lifetime';
  static const lifetimeLine = 'Yours for good. No renewals.';
  static const once = 'once';
  static const trialTag = '7 DAYS FREE';
  static const trialSpoken = '7 days free';

  static const unreachableTitle = "Couldn't reach the App Store";
  static const unreachableBody =
      'Check your connection. Your plan is saved on this phone.';
  static const tryAgain = 'Try again';

  static const waitingApproval = 'Waiting for approval';
  static const purchaseFailed = "The purchase didn't go through. Try again.";
  static const noPurchases = 'No purchases found for this Apple ID';

  static const terms = 'Terms';
  static const privacy = 'Privacy';

  static const lockedTitle = 'Your progress is saved';
  static const _comesBack = 'Everything here comes back the moment you do.';
  static String lockedEnded(String plan, String date) =>
      'Your $plan plan ended on $date. $_comesBack';
  static String lockedHasEnded(String plan) =>
      'Your $plan plan has ended. $_comesBack';
  static const lockedPlanEnded = 'Your plan has ended. $_comesBack';
  static String daysOnPlan(int days) =>
      days == 1 ? '1 day on plan' : '$days days on plan';
  static String avoided(String count, String units) => '$count $units avoided';
  static String saved(String money) => '$money saved';
  static String stageOf(int stage, int count) => 'stage $stage of $count';
  static const seeOffers = 'See offers';
  static const restorePurchases = 'Restore purchases';
}
