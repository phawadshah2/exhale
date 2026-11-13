import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const offers = FakeStoreRepository.defaultOffers;
  final usedTrial = [
    for (final o in offers)
      Offer(
        plan: o.plan,
        displayPrice: o.displayPrice,
        price: o.price,
        currencyCode: o.currencyCode,
        currencySymbol: o.currencySymbol,
        trialEligible: false,
      ),
  ];

  PaywallContent content(
    PlanKind selected, {
    List<Offer> offers = offers,
    int? coverDays = 4,
  }) => paywallContent(
    selected: selected,
    offers: offers,
    coverDays: coverDays,
    spendNoun: 'pods',
  );

  List<(StepIcon, String, String, String, String)> steps(PaywallContent c) => [
    for (final s in c.steps) (s.icon, s.title, s.body, s.rowTitle, s.word),
  ];

  test('Annual with the free week', () {
    final c = content(PlanKind.annual);
    expect(c.headline, 'Quitting is hard. Trying Exhale is free.');
    expect(c.showTrialTag, isTrue);
    expect(c.button, 'Start my free week');
    expect(c.stat, (
      days: '4 days',
      sentence: 'of pods costs more than a year of Exhale.',
    ));
    expect(steps(c), [
      (
        StepIcon.open,
        'Today',
        'Everything opens. Your plan starts.',
        'Today',
        'Full access',
      ),
      (
        StepIcon.bell,
        'Day 5',
        'We remind you, before any charge.',
        'Day 5',
        'We remind you',
      ),
      (
        StepIcon.card,
        'Day 7',
        r'Your year starts: $34.99.',
        'Day 7',
        'Year starts',
      ),
    ]);
  });

  test('Annual with the trial used', () {
    final c = content(PlanKind.annual, offers: usedTrial);
    expect(c.headline, "Quitting is hard. Starting isn't.");
    expect(c.showTrialTag, isFalse);
    expect(c.button, 'Subscribe');
    expect(steps(c), [
      (
        StepIcon.open,
        'Today',
        r'Everything opens. $34.99 is charged.',
        'Today',
        'Full access',
      ),
      (
        StepIcon.renew,
        'Each year',
        r'Renews at $34.99 until you cancel.',
        'Yearly',
        'Renews',
      ),
      (
        StepIcon.cancel,
        'Any time',
        'Cancel in Settings, keep the year.',
        'Any time',
        'Cancel',
      ),
    ]);
  });

  test('Monthly', () {
    final c = content(PlanKind.monthly, coverDays: 1);
    expect(c.headline, 'Quitting is hard. Trying Exhale is free.');
    expect(c.showTrialTag, isTrue);
    expect(c.button, 'Subscribe');
    expect(c.stat, (
      days: '1 day',
      sentence: 'of pods costs more than a month of Exhale.',
    ));
    expect(steps(c), [
      (
        StepIcon.open,
        'Today',
        r'Everything opens. $7.99 is charged.',
        'Today',
        'Full access',
      ),
      (
        StepIcon.renew,
        'Each month',
        r'Renews at $7.99 until you cancel.',
        'Monthly',
        'Renews',
      ),
      (
        StepIcon.cancel,
        'Any time',
        'Cancel in Settings, keep the month.',
        'Any time',
        'Cancel',
      ),
    ]);
  });

  test('Lifetime', () {
    final c = content(PlanKind.lifetime, coverDays: 7);
    expect(c.button, 'Buy once');
    expect(c.stat, (
      days: '7 days',
      sentence: 'of pods costs more than Exhale for good.',
    ));
    expect(steps(c), [
      (
        StepIcon.open,
        'Today',
        r'Everything opens. $59.99, once.',
        'Today',
        'Full access',
      ),
      (
        StepIcon.done,
        'After that',
        'Nothing more to pay. No renewals.',
        'After',
        'Nothing to pay',
      ),
      (
        StepIcon.forGood,
        'For good',
        'Staying at zero is included.',
        'For good',
        'Yours',
      ),
    ]);
  });

  test('no stat without the number of days', () {
    expect(content(PlanKind.annual, coverDays: null).stat, isNull);
  });

  test("prices come from the offers' display prices", () {
    final dirhams = [
      for (final o in offers)
        Offer(
          plan: o.plan,
          displayPrice: 'AED ${o.price}',
          price: o.price,
          currencyCode: 'AED',
          currencySymbol: 'AED',
          trialEligible: o.trialEligible,
        ),
    ];
    expect(
      content(PlanKind.annual, offers: dirhams).steps.last.body,
      'Your year starts: AED 34.99.',
    );
    expect(
      content(PlanKind.lifetime, offers: dirhams).steps.first.body,
      'Everything opens. AED 59.99, once.',
    );
  });

  test('with no offers the headline offers the free week', () {
    final c = content(PlanKind.annual, offers: const []);
    expect(c.headline, 'Quitting is hard. Trying Exhale is free.');
    expect(c.showTrialTag, isTrue);
  });
}
