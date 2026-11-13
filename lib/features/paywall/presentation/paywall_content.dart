import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:meta/meta.dart';

enum StepIcon { open, bell, card, renew, cancel, done, forGood }

/// One step of what happens after the button. [title] and [body] go down the
/// page; [rowTitle] and [word] go in the icon row on small iPhones.
@immutable
class PaywallStep {
  const PaywallStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.rowTitle,
    required this.word,
  });

  final StepIcon icon;
  final String title;
  final String body;
  final String rowTitle;
  final String word;
}

/// What follows the selected plan; the plan cards never change.
@immutable
class PaywallContent {
  const PaywallContent({
    required this.headline,
    required this.stat,
    required this.steps,
    required this.button,
    required this.showTrialTag,
  });

  final String headline;

  /// "4 days" and the sentence after it; null when there is no stat.
  final ({String days, String sentence})? stat;
  final List<PaywallStep> steps;
  final String button;

  /// The free week is still open, so Annual carries its tag.
  final bool showTrialTag;
}

/// [coverDays] comes from `daysToCover` for the selected plan. With no
/// offers loaded the free week is assumed, as for a first-time user.
PaywallContent paywallContent({
  required PlanKind selected,
  required List<Offer> offers,
  required int? coverDays,
  required String spendNoun,
}) {
  String price(PlanKind plan) =>
      offers.where((o) => o.plan == plan).firstOrNull?.displayPrice ?? '';
  final trial =
      offers
          .where((o) => o.plan == PlanKind.annual)
          .firstOrNull
          ?.trialEligible ??
      true;
  final cost = price(selected);

  const today = (title: PaywallCopy.today, word: PaywallCopy.fullAccess);
  PaywallStep opens(String body) => PaywallStep(
    icon: StepIcon.open,
    title: today.title,
    body: body,
    rowTitle: today.title,
    word: today.word,
  );
  PaywallStep renews(String title, String rowTitle) => PaywallStep(
    icon: StepIcon.renew,
    title: title,
    body: PaywallCopy.renewsBody(cost),
    rowTitle: rowTitle,
    word: PaywallCopy.renewsWord,
  );
  PaywallStep cancel(String body) => PaywallStep(
    icon: StepIcon.cancel,
    title: PaywallCopy.anyTime,
    body: body,
    rowTitle: PaywallCopy.anyTime,
    word: PaywallCopy.cancelWord,
  );

  final (steps, button, period) = switch (selected) {
    PlanKind.annual when trial => (
      [
        opens(PaywallCopy.opensPlanStarts),
        const PaywallStep(
          icon: StepIcon.bell,
          title: PaywallCopy.day5,
          body: PaywallCopy.remindBody,
          rowTitle: PaywallCopy.day5,
          word: PaywallCopy.remindWord,
        ),
        PaywallStep(
          icon: StepIcon.card,
          title: PaywallCopy.day7,
          body: PaywallCopy.yearStartsBody(cost),
          rowTitle: PaywallCopy.day7,
          word: PaywallCopy.yearStartsWord,
        ),
      ],
      PaywallCopy.startFreeWeek,
      PaywallCopy.aYear,
    ),
    PlanKind.annual => (
      [
        opens(PaywallCopy.opensCharged(cost)),
        renews(PaywallCopy.eachYear, PaywallCopy.yearly),
        cancel(PaywallCopy.cancelKeepYear),
      ],
      PaywallCopy.subscribe,
      PaywallCopy.aYear,
    ),
    PlanKind.monthly => (
      [
        opens(PaywallCopy.opensCharged(cost)),
        renews(PaywallCopy.eachMonth, PaywallCopy.monthly),
        cancel(PaywallCopy.cancelKeepMonth),
      ],
      PaywallCopy.subscribe,
      PaywallCopy.aMonth,
    ),
    PlanKind.lifetime => (
      [
        opens(PaywallCopy.opensOnce(cost)),
        const PaywallStep(
          icon: StepIcon.done,
          title: PaywallCopy.afterThat,
          body: PaywallCopy.nothingMoreBody,
          rowTitle: PaywallCopy.after,
          word: PaywallCopy.nothingWord,
        ),
        const PaywallStep(
          icon: StepIcon.forGood,
          title: PaywallCopy.forGoodTitle,
          body: PaywallCopy.stayingIncluded,
          rowTitle: PaywallCopy.forGoodTitle,
          word: PaywallCopy.yoursWord,
        ),
      ],
      PaywallCopy.buyOnce,
      PaywallCopy.forGood,
    ),
  };

  return PaywallContent(
    headline: trial ? PaywallCopy.headlineTrial : PaywallCopy.headlineNoTrial,
    stat: coverDays == null
        ? null
        : (
            days: PaywallCopy.statDays(coverDays),
            sentence: PaywallCopy.statSentence(spendNoun, period),
          ),
    steps: steps,
    button: button,
    showTrialTag: trial,
  );
}
