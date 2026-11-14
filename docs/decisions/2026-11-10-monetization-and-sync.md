# Monetization, data and sync (locked by Fawad, 2026-11-10)

Product decisions only. Each item still gets a spec and a plan before code. Mockups were
shown in the session of 2026-11-10 (not saved in `design/`).

## Paywall

- Free download, hard paywall right after the plan reveal in onboarding. Nothing is free
  after the trial or subscription ends: no logging, no plan. Data is never deleted.
- Three offers (starting prices, change one at a time from App Store Connect numbers,
  Lifetime first):
  - Annual US$34.99, selected by default, 7-day free trial, auto-renews. Pitch: "Your plan,
    plus a year at zero".
  - Monthly US$7.99, no trial.
  - Lifetime US$59.99, one-time, no trial.
- Annual and Monthly are auto-renewable subscriptions in one subscription group. Lifetime
  is a non-consumable. One trial per Apple account per group (Apple enforces it).
- Under the button, the trial as a timeline: today everything open, day 5 we remind you,
  day 7 charged.
- The money card's figure on the paywall: "Exhale pays for itself in N days".
- Restore purchases on the paywall, the locked screen and Settings.
- StoreKit 2 through `in_app_purchase`. No third-party SDK; entitlements are checked on
  the device, offline. The privacy label stays "Data Not Collected".
- Billing grace period on in App Store Connect: the app keeps working while Apple retries.

## Locked screen (trial or subscription ended)

Shows the saved progress (days on plan, units avoided, money kept, stage), "See offers"
and "Restore purchases". Everything returns as it was on payment.

## Payment notifications (local, scheduled on the device)

- Trial day 5: "Your free week ends in 2 days. Keep going, or cancel in Settings."
- 7 days before an Annual renewal: "If you're still subscribed, Exhale renews on {date}
  for {price}."
- Quit date reached: congratulations, the renewal date, keep it or cancel.
- Card failed: an in-app banner, not a notification.
- Subscription ended: one notification, "Your progress is saved."
- Reschedule from the live StoreKit status on every app open. One notification per event,
  no nagging. Apple handles receipts, price-increase consent, billing retry and win-back
  offers.

## Data: export, import, iCloud sync (in the launch build)

- Export to Files and Import a file (replaces this phone's data after a confirmation).
- iCloud sync through CloudKit in the user's own iCloud; no server of ours. Synced: plan,
  logs, holds, stage checks, prices, day boundary. Per phone: theme and accent.
- One plan per account in the launch build (one habit). Settings > Your data: iCloud sync,
  last synced, "Keep this phone separate" (sync off; that phone keeps its own local habit),
  Export, Import, Restore purchases.
- Turning sync on when both iCloud and the phone have a plan: "Two plans found", offer
  Export first, then "Use the iCloud plan" or "Keep this phone's plan". Never a silent merge.
- Fawad sets up the iCloud capability and CloudKit container in the developer account.
- Fallback, only on Fawad's call: Export/Import at launch, sync in 1.0.1.

## A second phone, same App Store account

On first open, check the StoreKit entitlement and iCloud before showing anything:

| Found | Phone B shows |
|---|---|
| Subscription and iCloud plan | No onboarding: "Welcome back", Use my plan, or start fresh |
| Subscription, no iCloud plan | "You're already subscribed": Set up my plan (no paywall at the end) or Import a file |
| iCloud plan, no subscription | Restore the data, then the locked screen |
| iCloud unreachable | "Couldn't reach iCloud": Try again or Start fresh |

## Stay at zero (right after the paywall, before the first users reach their quit date)

Turns on at the quit date. Wording stays habit-neutral (not "sober").

- Home: a days-free ring, money kept, units avoided, the next milestone.
- "I'm craving": a 2-minute ride-it-out breathing screen; records time and trigger, not a slip.
- Log a slip without shame: "1 slip in 41 days", the counter restarts, the record stays.
- Craving patterns from triggers ("after meals, around 9 pm").
- Milestones in days and money only, no medical claims.
- Safety net: 3 slips in 3 days offers a short taper ("ease back down over 2 weeks").

## After launch

Multiple habits with one subscription covering every habit, then reminders, widgets and
the Live Activity, time-of-day insights, habit reordering.
