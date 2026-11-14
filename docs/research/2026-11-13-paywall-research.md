# Paywall research (2026-11-13)

What makes a subscription paywall convert, read for Exhale: a hard paywall after the plan
reveal, Annual with a 7-day trial, Monthly, Lifetime. Most figures are vendor data
(RevenueCat, Adapty, Superwall) from their own customers, so they are directional.

## Findings

1. **Structure beats looks.** Adapty's experiment data: trial structure, plan length and
   number-of-plans tests win on lifetime value 57 to 60% of the time; visual and copy-only
   tests win 35%, the lowest. The decisions already locked (hard paywall, trial, Annual
   default) matter more than which layout is picked.
2. **A hard paywall is the right call.** RevenueCat 2026: hard paywalls convert a median
   10.7% of downloads by day 35 against 2.1% for freemium, with the same one-year retention
   (27% against 28%).
3. **The decision happens once, on day 0.** Adapty: 90% of trial starts happen on the day
   of install, and onboarding paywalls convert best. What comes before the paywall decides
   it: one test went from 2% to 15% trial starts by adding three context screens before it.
   Exhale's chat and plan reveal are that context.
4. **Health & Fitness suits our offers.** It is the one category where annual plans keep
   growing; trials help there; most of its trials run 4 to 7 days.
5. **Say how the trial works.** Blinkist's "honest paywall" (a timeline, what is included,
   a promise to remind before charging) raised conversion 23% and cut complaints 55%.
   Superwall: a reminder promise is the best defence against people cancelling the moment
   the trial starts (20 to 30% of cancellations happen in the first three hours). The
   timeline is common now, so it is less novel than it was.
6. **Spread it over a few steps.** Superwall reports a three-step paywall (the value, the
   reminder promise, the purchase) winning in 97% of its tests across categories, because
   each step answers one worry.
7. **Lead with Annual, show fewer choices.** RevenueCat: Annual as the default and only
   visible offer, with the rest behind "View all plans", lifted annual take-up 15 to 20%.
   The trial on Annual only is the current pattern among top apps. Two or three offers at
   most.
8. **Anchor the price against something familiar.** Everyday comparisons and savings
   figures work. Exhale has the strongest honest anchor there is: the user's own spend on
   the habit, from their answers.
9. **Reuse the user's answers.** A paywall that "speaks to you" converts better; a short
   value recap should bridge onboarding and the paywall.
10. **Plain words.** Clear copy beats clever copy at the moment of paying. Put the free
    trial in the headline and repeat it ("no payment due now", "cancel any time").
11. **A little motion helps** (vendor claim: 12 to 18%): gentle entrances, nothing
    decorative.
12. **After the purchase matters.** One screen that confirms the choice and says what
    happens next lowers early cancellations.
13. **Social proof is optional.** Only 27% of the top 100 iOS paywalls use it. Exhale has
    none yet and must not invent any; add the App Store rating once it is real.

## Apple's rules (must hold in every design)

From Apple's auto-renewable subscriptions page and guideline 3.1.2:

- The amount billed is the most prominent price on the screen. A per-month breakdown or a
  saving is allowed only smaller and below it. So "$34.99/year" leads; "$2.92/mo" is small.
  A headline built on "$2.92 a month" breaks this.
- A trial must state its length and the price charged after it.
- The offer's name, its length and what it includes are on the screen.
- Restore purchases, Terms of Use and Privacy Policy are reachable from the screen. With
  Apple's standard licence, the terms link also goes in the App Store description.

## What this means for Exhale

- Keep: hard paywall, three offers, Annual default, the trial on Annual only, the day-5
  reminder (it must ship in the same release as the paywall that promises it).
- The paywall should carry: the free week in the headline, how the week works, the user's
  own numbers as the anchor, the billed price as the biggest price, "no payment due now",
  Restore, Terms, Privacy.
- A risk in our prices: a plan runs 4 to 12 weeks, so Monthly for two or three months costs
  less than Annual. The paywall has to sell the year (the taper plus staying at zero).
- No analytics by design, so no A/B tests: pick the layout the evidence favours and watch
  trials and sales in App Store Connect.

## Sources

- RevenueCat, State of Subscription Apps 2026 summary: https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026
- Adapty, What does a high-performing paywall look like in 2026: https://adapty.io/blog/high-performing-paywall-2026/
- Adapty, State of paywalls 2026: https://adapty.io/state-of-paywalls/report/
- RevenueCat, What the best subscription apps get right about paywalls: https://www.revenuecat.com/blog/growth/how-top-apps-approach-paywalls/
- RevenueCat, 5 overlooked paywall improvements: https://www.revenuecat.com/blog/growth/paywall-conversion-boosters
- RevenueCat, 8 paywall test ideas: https://www.revenuecat.com/blog/growth/paywall-tests-grow-app-revenue
- Superwall, Two paywall trends driving ARPU gains: https://superwall.com/blog/two-paywall-trends-driving-arpu-gains
- Apple's subscription paywall rules, summarised from Apple's pages: https://www.builtbyfoundry.io/blog/apple-subscription-paywall-rules-2026-7-things-sign-up-screen
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Paywall gallery: https://www.paywalls.com
